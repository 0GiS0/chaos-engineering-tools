##############################################################
################## Install Litmus using Helm #################
##############################################################

kubectx $1

echo "Add the Litmus Helm repository"
helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/
helm repo list

echo "Create the namespace to install Litmus"
kubectl create ns litmus

echo "Install Litmus using Helm"
helm install chaos litmuschaos/litmus --namespace=litmus

echo "Wait for the pods to be ready"
kubectl wait --for=condition=Ready pods --all -n litmus --timeout=600s