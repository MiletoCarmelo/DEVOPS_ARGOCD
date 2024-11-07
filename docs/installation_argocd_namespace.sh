#installation : 
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# define variable for password
export PASS=$(kubectl --namespace argocd get secret argocd-initial-admin-secret --output jsonpath="{.data.password}" \
        | base64 --decode)
echo $PASS

# define variable env for port used for argo_cd : 
export BASE_HOST=localhost:8090
echo $BASE_HOST

# forward port 443 to 8090 : 
kubectl --namespace argocd port-forward svc/argocd-server 8090:443 &

# login into argocd:
argocd login --insecure --username admin --password $PASS --grpc-web $BASE_HOST

# update password to Admin123 (to keep the same on firefox):
argocd account update-password --current-password $PASS --new-password Admin123

# INSTALLATION DES METRICS DE CONTROLE USAGE MEMOIRE :
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# login into argocd:
argocd login --insecure --username admin --password Admin123 --grpc-web $BASE_HOST