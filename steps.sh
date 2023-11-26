# Install kubectx to change the context easily
# https://github.com/ahmetb/kubectx
brew install kubectx

####################################################
################### Litmus #########################
####################################################
source 00-cluster.sh "litmus-demo" "litmus-k8s"
source 01-litmus.sh "litmus-k8s"

kubectl port-forward svc/chaos-litmus-frontend-service -n litmus 9091:9091 # admin/litmus

# Delete litmus context from kubectx
kubectx -d litmus-k8s
# Delete resources
az group delete --name litmus-demo --yes --no-wait

####################################################
################### Chaos Mesh #####################
####################################################
source 00-cluster.sh "chaos-mesh-demo" "chaos-mesh-k8s"
source 02-chaos-mesh.sh "chaos-mesh-k8s"

# Port forward to access the dashboard in background
kubectl port-forward svc/chaos-dashboard -n chaos-mesh 2333:2333 &

# Access Kiali dashboard in background
kubectl port-forward svc/kiali -n istio-system 20001:20001 &

# Change environment variable of tour-of-heroes-web deployment to use tour-of-heroes-api service
kubectl set env deployment/tour-of-heroes-web -n tour-of-heroes API_URL="http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero"
kubectl describe deployment tour-of-heroes-web -n tour-of-heroes | grep API_URL

# Load some heroes
source 000-load-heroes.sh $(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

echo "Access Tour of heroes web: http://$(kubectl get svc tour-of-heroes-web -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')"
echo "Access Tour of heroes API: http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero"


# Generate load
hey -c 2 -z 200s http://$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/api/hero &
hey -c 2 -z 200s http://20.73.146.84/heroes &

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

