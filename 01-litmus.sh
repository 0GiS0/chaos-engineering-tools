# https://medium.com/@sunitparekh/step-by-step-guide-to-chaos-testing-using-litmus-chaos-toolkit-c5480f0f6ad0

# There are 4 major steps for running any chaos test.

# The first step is defining a steady state, which means defining how an ideal system would look like. For a web application, the home page is returning a success response, for a web service this would mean that it is healthy or it is returning a success for the health endpoint.
# The second step is actually introducing chaos such as simulating a failure such as a network bottleneck / disk fill etc.
# The third step is to verify a steady state, i.e, to check if the system is still working as expected.
# The fourth step which is the most important step (more important if you are running in production) is that we roll back the chaos that we caused.


# Step 1: Define steady state
# brew install hey
# API_IP=$(kubectl get svc tour-of-heroes-api -n tour-of-heroes -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
# hey -c 2 -z 200s http://$API_IP:8080/api/hero 

# Step 2: Introduce chaos
# All set, now time to introduce chaos in the system. Let’s first understand Litmus core concepts before we jump into execution.

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

# Access the Litmus ChaosCenter
# kubectl port-forward svc/chaos-litmus-frontend-service -n litmus 9091:9091 # admin/litmus

# Setup the Chaos Experiment
# The chaos experiment is defined in a YAML file.
# kubectl apply -f https://hub.litmuschaos.io/api/chaos/main?file=charts/generic/pod-network-latency/experiment.yaml
