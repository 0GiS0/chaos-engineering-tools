# Variables
RESOURCE_GROUP="chaos-demos"
AKS_NAME="chaos-k8s"
LOCATION="westeurope"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create AKS cluster
az aks create \
--resource-group $RESOURCE_GROUP \
--name $AKS_NAME \
--enable-addons monitoring \
--generate-ssh-keys

# Get credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME


#  first we need to have an application under test

# Deploy tour of heroes in tour-of-heroes namespace
kubectl create namespace tour-of-heroes
kubectl apply -f k8s/manifests --recursive -n tour-of-heroes

# Get all resources
kubectl get all -n tour-of-heroes

az extension add --name aks-preview


# Istio add-on
az feature register --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
az feature show --namespace "Microsoft.ContainerService" --name "AzureServiceMeshPreview"
az provider register --namespace Microsoft.ContainerService

# Install Istio add-on for existing cluster
az aks mesh enable --resource-group ${RESOURCE_GROUP} --name ${AKS_NAME}
az aks show --resource-group ${RESOURCE_GROUP} --name ${CLUSTER}  --query 'serviceMeshProfile.mode'

kubectl get pods -n aks-istio-system
kubectl label namespace tour-of-heroes istio.io/rev=asm-1-17

kubectl get pods -n tour-of-heroes
kubectl describe ns tour-of-heroes
kubectl delete pod --all -n tour-of-heroes
watch kubectl get pods -n tour-of-heroes

# Install Kiali
kubectl create ns istio-system
kubectl apply -f https://raw.githubusercontent.com/istio/istio/master/samples/addons/kiali.yaml
watch kubectl get pods -n istio-system
kubectl port-forward svc/kiali 20001:20001 -n istio-system

# Enable external ingress gateway

