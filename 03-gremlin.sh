#Deploy the Helm chart
helm repo add gremlin https://helm.gremlin.com/
kubectl create namespace gremlin

# Install the chart
helm install gremlin gremlin/gremlin \
    --namespace gremlin \
    --set  gremlin.secret.type=secret \
    --set  gremlin.secret.managed=true \
    --set  gremlin.hostPID=true \
    --set  gremlin.secret.teamID=27c7ba6b-d44f-4656-87ba-6bd44fc65684 \
    --set  gremlin.secret.clusterID=$1 \
    --set  gremlin.secret.teamSecret=943f6b65-6b98-492c-bf6b-656b98192c4e

# watch kubectl get pods -n gremlin
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=gremlin -n gremlin --timeout=120s

