kubectx $1

# Install Chaos Mesh using Helm
helm repo add chaos-mesh https://charts.chaos-mesh.org
helm search repo chaos-mesh

# Create the namespace to install Chaos Mesh
kubectl create ns chaos-mesh

# Install Chaos Mesh
helm install chaos-mesh chaos-mesh/chaos-mesh -n=chaos-mesh --set chaosDaemon.runtime=containerd --set chaosDaemon.socketPath=/run/containerd/containerd.sock --version 2.6.2
# watch kubectl get pods --namespace chaos-mesh -l app.kubernetes.io/instance=chaos-mesh
kubectl wait --for=condition=Ready pods --all -n chaos-mesh --timeout=600s

