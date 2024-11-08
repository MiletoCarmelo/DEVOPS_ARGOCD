# attention : a run dans le dossier mere de DEVOPS_ARGOCD avec : 
# ./scripts/installation_argocd_namespace.sh (sh ./scripts/installation_argocd_namespace.sh)

# get imputs : 
# Avec une vérification du nombre d'arguments
echo "purge minikube ? (yes or no)" 
read purge

# check if minikube is running if not start it :
if [ "$purge" = "yes" ]; then
    if ! minikube status > /dev/null 2>&1; then
        echo "minikube is not started"
    else
        echo "minikube already started...it will be purged"
        minikube delete > /dev/null 2>&1
        echo "minikube purged"
    fi
    minikube start --driver=hyperkit
    echo "minikube started"

    # check if namespace argocd already exist if not install it :
    if kubectl get namespace argocd > /dev/null 2>&1; then
        echo "namespace argocd already exist"
    else
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        echo "namespace argocd created"
    fi
    echo "argocd processing ...." 
    sleep 120
fi

# define variable for password
export PASS=$(kubectl --namespace argocd get secret argocd-initial-admin-secret --output jsonpath="{.data.password}" \
        | base64 --decode)
echo $PASS

# define variable env for port used for argo_cd : 
export PORT=8090
export BASE_HOST=localhost:$PORT
echo $BASE_HOST

# check if port 8090 is already used if yes kill the process :
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    kill -9 $(lsof -t -i:$PORT)
    echo "port $PORT is already used, and the process is killed"
fi
# forward port 443 to 8090 : 
kubectl --namespace argocd port-forward svc/argocd-server 8090:443 > /dev/null 2>&1 & 
PORT_FORWARD_PID=$!
sleep 5

# Pour arrêter le port-forward plus tard si nécessaire :
# kill $PORT_FORWARD_PID
echo "port 443 is forwarded to $PORT"

# login into argocd:
argocd login --insecure --username admin --password $PASS --grpc-web $BASE_HOST

# update password to Admin123 (to keep the same on firefox):
argocd account update-password --current-password $PASS --new-password Admin123

# INSTALLATION DES METRICS DE CONTROLE USAGE MEMOIRE :
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# login into argocd:
argocd login --insecure --username admin --password Admin123 --grpc-web $BASE_HOST

# apply the argocd app :
kubectl apply -f argocd-components-app.yaml