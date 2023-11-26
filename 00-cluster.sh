############################################################################
########## Monitoring AKS cluster with Prometheus and Grafana ##############
############################################################################

# Register providers
# az provider register --namespace Microsoft.ContainerService
# az provider register --namespace Microsoft.Insights
# az provider register --namespace Microsoft.AlertsManagement

# Variables
# LOCATION=westeurope
# RESOURCE_GROUP=kiali-aks
# AKS_NAME=my-cluster
LOCATION=westeurope
RESOURCE_GROUP=$1
AKS_NAME=$2

echo "Creating AKS cluster $AKS_NAME ⎈ in resource group $RESOURCE_GROUP 📦 in location $LOCATION 🌍"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create Azure Monitor Workspace
# az resource create \
# --resource-group $RESOURCE_GROUP \
# --namespace microsoft.monitor \
# --resource-type accounts \
# --name $AKS_NAME-workspace \
# --location $LOCATION \
# --properties "{}"

# Create Managed Grafana
# GRAFANA_ID=$(az grafana create \
# --name $AKS_NAME-grafana \
# --resource-group $RESOURCE_GROUP \
# -o tsv --query id)

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create AKS cluster
# az aks create \
# --resource-group $RESOURCE_GROUP \
# --name $AKS_NAME \
# --enable-azure-monitor-metrics \
# --generate-ssh-keys \
# --azure-monitor-workspace-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/microsoft.monitor/accounts/$AKS_NAME-workspace" \
# --grafana-resource-id "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/microsoft.dashboard/grafana/$AKS_NAME-grafana" \
# --enable-managed-identity
az aks create \
--resource-group $RESOURCE_GROUP \
--name $AKS_NAME \
--enable-azure-monitor-metrics \
--generate-ssh-keys

# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

# Import Grafana dashboard 6417
# Monitoring app 16491 https://grafana.com/tutorials/k8s-monitoring-app/

# # Install certmanager
# kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.2/cert-manager.yaml
# watch kubectl get all -n cert-manager

# # Install Jaeger Operator
# kubectl create namespace observability # This creates the namespace used by default in the deployment files
# kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.51.0/jaeger-operator.yaml -n observability # The operator will be installed in cluster wide mode

# # At this point, there should be a jaeger-operator deployment available. 
# watch kubectl get pods -n observability

# # Deploy tour of heroes
# kubectl create ns tour-of-heroes
# kubectl apply -f k8s/manifests --recursive -n tour-of-heroes
# watch kubectl get pods -n tour-of-heroes

# API_IP=$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# hey -c 2 -z 200s http://$API_IP:8080/api/hero 

# # Deploy jaeger instance
# kubectl apply -f - <<EOF
# apiVersion: jaegertracing.io/v1
# kind: Jaeger
# metadata:
#   name: simplest
#   namespace: observability
# EOF

# kubectl logs -l app.kubernetes.io/instance=simplest

# # Access Jaeger UI
# kubectl port-forward -n observability svc/simplest-query 16686:16686

# # Integrate jaeger with prometheus
# kubectl apply -f - <<EOF
# apiVersion: jaegertracing.io/v1
# kind: Jaeger
# metadata:
#   name: jaeger-collector
#   namespace: observability
# spec:
#   strategy: production
#   collector:
#     resources:
#       limits:
#         memory: 2Gi
#       requests:
#         memory: 1Gi
#   storage:
#     type: elasticsearch
#     options:
#       es:
#         server-urls: http://elasticsearch-master:9200
#         username: elastic
#         password: changeme
# EOF

echo "Create namespace istio-system"
kubectl create ns istio-system

echo "Deploying Prometheus"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/prometheus.yaml

echo "Deploying Jaeger"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/jaeger.yaml

echo "Deploying Grafana"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/grafana.yaml

# watch kubectl get pods -n istio-system

echo "Installing Istio"
curl -L https://istio.io/downloadIstio | sh -
cd istio-1.20.0

export PATH=$PWD/bin:$PATH

istioctl install --set profile=demo -y

echo "Deploying tour of heroes"
kubectl create ns tour-of-heroes
echo "Labeling namespace tour-of-heroes with istio-injection=enabled"
kubectl label namespace tour-of-heroes istio-injection=enabled

cd ..
echo "Deploying tour of heroes"
kubectl apply -f k8s/manifests --recursive -n tour-of-heroes

echo "Wait for pods to be ready"
kubectl wait --for=condition=Ready pods --all -n tour-of-heroes --timeout=600s

echo "Deploying Kiali"
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.20/samples/addons/kiali.yaml

echo "Wait for pods to be ready"
kubectl wait --for=condition=Ready pods --all -n istio-system --timeout=600s

echo "Ready to go!"
# Access Kiali UI
# kubectl port-forward svc/kiali 20001:20001 -n istio-system