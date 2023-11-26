# Delete litmus context from kubectx
kubectx -d $2
# Delete resources
az group delete --name $1 --yes --no-wait