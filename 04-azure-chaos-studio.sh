# Variables
RESOURCE_GROUP="chaos-demos"
AKS_NAME="chaos-k8s"
LOCATION="westeurope"

# Chaos Studio uses Chaos Mesh, a free, open-source chaos engineering platform for Kubernetes, to inject faults into an AKS cluster. Chaos Mesh faults are service-direct faults that require Chaos Mesh to be installed on the AKS cluster. 

# Before you can run Chaos Mesh faults in Chaos Studio, you must install Chaos Mesh on your AKS cluster (check chaos-mesh.sh)

# Enable Chaos Studio on your AKS cluster
# Chaos Studio can't inject faults against a resource unless that resource is added to Chaos Studio first. To add a resource to Chaos Studio, create a target and capabilities on the resource. AKS clusters have only one target type (service-direct), but other resources might have up to two target types. One target type is for service-direct faults. Another target type is for agent-based faults. 
# Each type of Chaos Mesh fault is represented as a capability like PodChaos, NetworkChaos, and IOChaos.

# Create a target by replacing $RESOURCE_ID with the resource ID of the AKS cluster you're adding.
AKS_RESOURCE_ID=$(az aks show --resource-group $RESOURCE_GROUP --name $AKS_NAME --query id --output tsv)
SUBSCRIPTION_ID=$(az account show --query id --output tsv)
API_VERSION="2023-11-01"

az rest --method put \
--url "https://management.azure.com/$AKS_RESOURCE_ID/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh?api-version=$API_VERSION" \
--body "{\"properties\":{}}"

# Create the capabilities on the target by replacing $RESOURCE_ID with the resource ID of the AKS cluster you're adding. Replace $CAPABILITY with the name of the fault capability you're enabling.
CAPABILITY="PodChaos"

az rest --method put \
--url "https://management.azure.com/$RESOURCE_ID/providers/Microsoft.Chaos/targets/Microsoft-AzureKubernetesServiceChaosMesh/capabilities/$CAPABILITY?api-version=2023-11-01"  \
--body "{\"properties\":{}}"

# Create an experiment
{"action":"pod-failure","mode":"all","selector":{"namespaces":["tour-of-heroes"]}}

# List all the targets or agents under a subscription
az rest --method get \
--url "https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Chaos/targets?api-version=$API_VERSION"

#List all the experiments in a resource group
az rest --method get \
--url "https://management.azure.com/$AKS_RESOURCE_ID/providers/Microsoft.Chaos/experiments?api-version=$API_VERSION" \
--resource "https://management.azure.com"