# Install kubectx to change the context easily
# https://github.com/ahmetb/kubectx
brew install kubectx

####################################################
################### Litmus #########################
####################################################
source 00-create-cluster.sh "litmus-demo" "litmus-k8s" 
source 02-litmus.sh "litmus-k8s"

kubectl port-forward svc/chaos-litmus-frontend-service -n litmus 9091:9091 # admin/litmus

# 1. Create an environment
    # 1.1. Environment name: tour-of-heroes
    # 1.2. Environment type: Pre-production
    # 1.3 Click on it
    # 1.4. Enable Chaos > Name: tour-of-chaos > Chaos Componentes Installation: Cluster-wide access > Installation location: litmus. Download YAML and run it

kubectl apply -f tour-of-chaos-litmus-chaos-enable.yml
watch kubectl get pods -n litmus

# 2. Create a resilience probe
# 2.1 Go to Resilience Probes > + New Probe > HTTP
# 2.2. Name: Tour of heroes API
# 2.3. Timeout: 5 seconds > Interval: 5 seconds > Consecutive failures: 2
echo "2.4 URL: http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero > METHOD:GET > Expected status code: 200"
# 3. Create a Chaos Experiment
# 3.1. Got to Chaos Experiments > + New Experiment > Name: dbdies; Select your Chaos Infraestructure
# 3.2. Templates from ChaosHubs > PodDelete > Use this template
# 3.3. Select run-chaos > App kind > Deployment ; App Namespace > tour-of-heroes ; App Label > app=tour-of-heroes-sql
# 3.4. Keep Tune Fault as it is
# 3.5 Probes > + Add Probe > Tour of heroes API > Mode: Continuous
# 3.6. Apply Changes > Apply Changes > Save & Run
# 3.7 This won't work (Issue: https://github.com/litmuschaos/litmus/issues/4246): I get this error from subscriber pod:
# time="2023-11-27T08:46:02Z" level=error msg="Error on processing request" error="error performing infra operation: Workflow.argoproj.io \"dbdies-1701074762792\" is invalid: metadata.labels: Invalid value: \"{{workflow.parameters.appNamespace}}_kube-proxy\": a valid label must be an empty string or consist of alphanumeric characters, '-', '_' or '.', and must start and end with an alphanumeric character (e.g. 'MyValue',  or 'my_value',  or '12345', regex used for validation is '(([A-Za-z0-9][-A-Za-z0-9_.]*)?[A-Za-z0-9])?')"
# 3.8 Download Manifest, commet subject: "{{workflow.parameters.appNamespace}}_kube-proxy" and execute locally
kubectl apply -f dbdies.yml
# 3.9. Check the chaos experiment
watch kubectl get pods -n litmus
# 4. Check the pods
watch kubectl get pods -n tour-of-heroes

#!IMPORTANT: Log out before delete the cluster
source 04-delete-resources.sh "litmus-demo" "litmus-k8s"
####################################################
################### Chaos Mesh #####################
####################################################
source 00-create-cluster.sh "chaos-mesh-demo" "chaos-mesh-k8s"
source 03-chaos-mesh.sh "chaos-mesh-k8s"

# Port forward to access the dashboard in background
kubectl port-forward svc/chaos-dashboard -n chaos-testing 2333:2333

# Create a experiment
# 1. Go to Experiments > + New experiment
# 2. Inject into Kubernetes > Pod Fault > Pod Failure
# 3. Experiment Info:
# 3.1. Scope > Namespace Selectors: tour-of-heroes; Label Selectors: app=tour-of-heroes-sql; Mode > All
# 3.2 Metadata > Name: dbdies; Namespace: chaos-mesh

# 4. Check the pods
watch kubectl get pods -n tour-of-heroes

source 04-delete-resources.sh "chaos-mesh-demo" "chaos-mesh-k8s"

####################################################
################ Azure Chaos Studio ################
####################################################
AKS_NAME="azchaos-k8s"
RESOURCE_GROUP="az-chaos-studio-demo"

source 00-create-cluster.sh $RESOURCE_GROUP $AKS_NAME

# Before you can run Chaos Mesh faults in Chaos Studio, you must install Chaos Mesh on your AKS cluster.
source 03-chaos-mesh.sh $AKS_NAME

# Port forward to access the dashboard in background
kubectl port-forward svc/chaos-dashboard -n chaos-testing 2333:2333

# Enable this cluster as a target for Chaos Studio
AKS_RESOURCE_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query id --output tsv)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
API_VERSION="2023-11-01"

az rest --method put \
--url "https://management.azure.com/$AKS_RESOURCE_ID/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=$API_VERSION" \
--body "{\"properties\":{}}"

# Create the capabilities on the target by replacing $RESOURCE_ID with the resource ID of the AKS cluster you're adding. Replace $CAPABILITY with the name of the fault capability you're enabling.
CAPABILITY="PodChaos-2.1"

az rest --method put \
--url "https://management.azure.com/$AKS_RESOURCE_ID/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/$CAPABILITY?api-version=$API_VERSION"  \
--body "{\"properties\":{}}"

# {"selector":{"namespaces":["tour-of-heroes"],"labelSelectors":{"app":"tour-of-heroes-sql"}},"mode":"all","action":"pod-failure","duration":"7m"}

EXPERIMENT_NAME=dbdies-from-cli

cat <<EOF > experiment.json
{
  "location": "westeurope",
  "identity": {
    "type": "SystemAssigned"
  },
  "properties": {
    "steps": [
      {
        "name": "AKS pod kill",
        "branches": [
          {
            "name": "AKS pod kill",
            "actions": [
              {
                "type": "continuous",
                "selectorId": "Selector1",
                "duration": "PT7M",
                "parameters": [
                  {
                      "key": "jsonSpec",
                      "value": "{'selector':{'namespaces':['tour-of-heroes'],'labelSelectors':{'app':'tour-of-heroes-sql'}},'mode':'all','action':'pod-failure'}"
                  }
                ],
                "name": "urn:csci:microsoft:azureKubernetesServiceChaosMesh:podChaos/2.1"
              }
            ]
          }
        ]
      }
    ],
    "selectors": [
      {
        "id": "Selector1",
        "type": "List",
        "targets": [
          {
            "type": "ChaosTarget",
            "id": "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.ContainerService/managedClusters/$AKS_NAME/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh"
          }
        ]
      }
    ]
  }
}
EOF

az rest \
--method put \
--uri "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Chaos/experiments/$EXPERIMENT_NAME?api-version=$API_VERSION" --body @experiment.json

# Get the principal ID por this experiment
EXPERIMENT_PRINCIPAL_ID=$(az resource show \
--resource-group $RESOURCE_GROUP \
--name $EXPERIMENT_NAME \
--resource-type Microsoft.Chaos/experiments \
--query identity.principalId \
--output tsv)

# Give the experiment permission to your AKS cluster
az role assignment create \
--role "Azure Kubernetes Service Cluster Admin Role" \
--assignee-object-id $EXPERIMENT_PRINCIPAL_ID \
--scope $AKS_RESOURCE_ID

# Run the experiment
az rest \
--method post \
--uri "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Chaos/experiments/$EXPERIMENT_NAME/start?api-version=$API_VERSION"

# Port forward to access the dashboard in background
kubectl port-forward svc/chaos-dashboard -n chaos-testing 2333:2333

#Check the pods
watch kubectl get pods -n tour-of-heroes

source 04-delete-resources.sh "az-chaos-studio-demo" "azchaos-k8s"
