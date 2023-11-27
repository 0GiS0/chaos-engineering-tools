# Install kubectx to change the context easily
# https://github.com/ahmetb/kubectx
brew install kubectx

####################################################
################### Litmus #########################
####################################################
source 00-cluster.sh "litmus-demo" "litmus-k8s"
source 01-litmus.sh "litmus-k8s"

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
source 05-delete-resources.sh "litmus-demo" "litmus-k8s"
####################################################
################### Chaos Mesh #####################
####################################################
source 00-cluster.sh "chaos-mesh-demo" "chaos-mesh-k8s"
source 02-chaos-mesh.sh "chaos-mesh-k8s"

# Port forward to access the dashboard in background
kubectl port-forward svc/chaos-dashboard -n chaos-mesh 2333:2333

# First thing: Generate a token to manage Chaos Mesh
# Cluster scope and Role > Manager
kubectl apply -f - <<EOF
kind: ServiceAccount
apiVersion: v1
metadata:
  namespace: default
  name: account-cluster-manager-vezjg

---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: role-cluster-manager-vezjg
rules:
- apiGroups: [""]
  resources: ["pods", "namespaces"]
  verbs: ["get", "watch", "list"]
- apiGroups: ["chaos-mesh.org"]
  resources: [ "*" ]
  verbs: ["get", "list", "watch", "create", "delete", "patch", "update"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: bind-cluster-manager-vezjg
subjects:
- kind: ServiceAccount
  name: account-cluster-manager-vezjg
  namespace: default
roleRef:
  kind: ClusterRole
  name: role-cluster-manager-vezjg
  apiGroup: rbac.authorization.k8s.io
EOF

# Generate token (available from Kubernetes 1.24+)
kubectl create token account-cluster-manager-vezjg

# Create a experiment
# 1. Go to Experiments > + New experiment
# 2. Inject into Kubernetes > Pod Fault > Pod Failure
# 3. Experiment Info:
# 3.1. Scope > Namespace Selectors: tour-of-heroes; Label Selectors: app=tour-of-heroes-sql; Mode > All
# 3.2 Metadata > Name: dbdies; Namespace: chaos-mesh

# 4. Check the pods
watch kubectl get pods -n tour-of-heroes


# Access Kiali dashboard in background
# kubectl port-forward svc/kiali -n istio-system 20001:20001 &

# Generate load
# hey -c 2 -z 200s http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero &
# hey -c 2 -z 200s http://20.73.146.84/heroes &

source 05-delete-resources.sh "chaos-mesh-demo" "chaos-mesh-k8s"

####################################################
################### Gremlin ########################
####################################################
source 00-cluster.sh "gremlin-demo" "gremlin-k8s"
source 03-gremlin.sh "gremlin-k8s"

# Change environment variable of tour-of-heroes-web deployment to use tour-of-heroes-api service
kubectl set env deployment/tour-of-heroes-web -n tour-of-heroes API_URL="http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero"
kubectl describe deployment tour-of-heroes-web -n tour-of-heroes | grep API_URL

# Load some heroes
source 000-load-heroes.sh $(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Access Tour of heroes web: http://$(kubectl get svc tour-of-heroes-web -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "Access Tour of heroes API: http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero"

# Create a gremlin experiment
source checks/00-check-pods.sh

source 05-delete-resources.sh "gremlin-demo" "gremlin-k8s"
####################################################
################ Azure Chaos Studio#################
####################################################
source 00-cluster.sh "az-chaos-studio-demo" "azchaos-k8s"

az group delete --name az-chaos-studio-demo --yes --no-wait

