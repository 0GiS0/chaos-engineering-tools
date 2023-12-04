LOCATION=westeurope
RESOURCE_GROUP=$1
AKS_NAME=$2

echo "Creating AKS cluster $AKS_NAME ⎈ in resource group $RESOURCE_GROUP 📦 in location $LOCATION 🌍"

# Create Resource Group
az group create --name $RESOURCE_GROUP --location $LOCATION

SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Create AKS cluster
az aks create \
--resource-group $RESOURCE_GROUP \
--name $AKS_NAME \
--node-vm-size Standard_B4ms \
--enable-azure-monitor-metrics \
--generate-ssh-keys

# Get AKS credentials
az aks get-credentials --resource-group $RESOURCE_GROUP --name $AKS_NAME --overwrite-existing

echo "Deploying tour of heroes"
kubectl create ns tour-of-heroes

echo "Deploying tour of heroes"
kubectl apply -f k8s/manifests --recursive -n tour-of-heroes

echo "Wait for pods to be ready"
kubectl wait --for=condition=Ready pods --all -n tour-of-heroes --timeout=600s
echo "Wait for svc to have external IP"
for svc in $(kubectl get svc -n tour-of-heroes -o jsonpath='{range .items[*]}{@.metadata.name}{":"}{@.spec.type}{"\n"}{end}' | grep LoadBalancer | cut -d: -f1); do
  while true; do
    ip=$(kubectl get svc $svc -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
    if [[ -z "$ip" ]]; then
      echo "Waiting for external IP for $svc..."
      sleep 10
    else
      echo "External IP for $svc is $ip"
      break
    fi
  done
done

echo "Ready to go!"

# Change environment variable of tour-of-heroes-web deployment to use tour-of-heroes-api service
kubectl set env deployment/tour-of-heroes-web -n tour-of-heroes API_URL="http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero"
kubectl describe deployment tour-of-heroes-web -n tour-of-heroes | grep API_URL

# Load some heroes
source 01-load-heroes.sh $(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Access Tour of heroes web: http://$(kubectl get svc tour-of-heroes-web -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "Access Tour of heroes API: http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero"