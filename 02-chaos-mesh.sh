kubectx $1

echo "Install Chaos Mesh using Helm"
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm search repo chaos-mesh

echo "Create the namespace to install Chaos Mesh"
kubectl create ns chaos-testing

echo "Install Chaos Mesh 𐄳"
helm install chaos-mesh chaos-mesh/chaos-mesh \
-n=chaos-testing \
--set chaosDaemon.runtime=containerd \
--set chaosDaemon.socketPath=/run/containerd/containerd.sock \
--set dashboard.securityMode=false

kubectl wait --for=condition=Ready pods --all -n chaos-testing --timeout=600s