#!/bin/bash

# attention : a run dans le dossier mere de DEVOPS_ARGOCD avec :
# ./scripts/installation_argocd_namespace.sh (sh ./scripts/installation_argocd_namespace.sh)

# check if macbook or linux
OS_TYPE=$(uname)

# get inputs :
echo "purge minikube / k3s ? (yes or no)"
read purge

if [ "$purge" = "yes" ]; then
    # Encoder la configuration complète en base64
    if [[ "$OS_TYPE" == "Darwin" ]]; then
        if ! minikube status > /dev/null 2>&1; then
            echo "minikube is not started"
        else
            echo "minikube already started...it will be purged"
            sudo minikube delete > /dev/null 2>&1
            echo "minikube purged"
        fi
        echo "🖥️ Vous êtes sur macOS."
        minikube start  --driver=hyperkit \
                        --memory=6g \
                        --cpus=4 \
                        --extra-config=apiserver.max-mutating-requests-inflight=2000 \
                        --extra-config=apiserver.max-requests-inflight=4000 \
                        --extra-config=etcd.quota-backend-bytes=4294967296 \
                        --extra-config=kubelet.authentication-token-webhook=true \
                        --extra-config=kubelet.authorization-mode=Webhook \
                        --extra-config=scheduler.bind-address=0.0.0.0 \
                        --extra-config=controller-manager.bind-address=0.0.0.0

                        
        echo "minikube started"
        minikube addons enable ingress
    elif [[ "$OS_TYPE" == "Linux" ]]; then
        echo "🐧 Vous êtes sur Linux."
        # Arrêter le service
        sudo systemctl stop k3s
        # Supprimer tous les workloads
        kubectl delete all --all -A
        # Puis désinstaller
        k3s-uninstall.sh
        # Puis le réinstaller
        curl -sfL https://get.k3s.io | sh -
        # Configurer l'accès
        mkdir -p ~/.kube
        sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
        sudo chown $USER:$USER ~/.kube/config
        sudo chmod 600 ~/.kube/config
        # Ajouter la variable d'environnement
        export KUBECONFIG=~/.kube/config
        echo "export KUBECONFIG=~/.kube/config" >> ~/.bashrc
    fi

    # check if namespace argocd exists
    if kubectl get namespace argocd > /dev/null 2>&1; then
        echo "namespace argocd already exists"
    else
        echo "Creating ArgoCD namespace and installing ArgoCD..."
        kubectl create namespace argocd
        kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
        
        # Wait for all ArgoCD pods to be ready
        echo "Waiting for ArgoCD pods to be ready..."
        kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
    fi
fi

# define variables for argocd setup
export PORT=8090
export BASE_HOST=localhost:$PORT
echo "ArgoCD will be accessible at: $BASE_HOST"

# check if port 8090 is already used
if lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null ; then
    echo "Port $PORT is in use. Killing existing process..."
    kill -9 $(lsof -t -i:$PORT)
    sleep 2
fi

# Wait for initial admin secret to be available
echo "Waiting for ArgoCD initial admin secret..."
while ! kubectl -n argocd get secret argocd-initial-admin-secret &>/dev/null; do
    echo "Waiting for initial admin secret to be created..."
    sleep 10
done

# Get initial admin password
export PASS=$(kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)
echo "Initial admin password retrieved"

# Setup port forwarding
echo "Setting up port forwarding..."
kubectl port-forward svc/argocd-server -n argocd $PORT:443 &
PORT_FORWARD_PID=$!

# Wait for port-forward to be established
echo "Waiting for port-forward to be established..."
for i in {1..12}; do
    if nc -z localhost $PORT; then
        echo "Port-forward is ready"
        break
    fi
    if [ $i -eq 12 ]; then
        echo "Port-forward failed to establish"
        kill $PORT_FORWARD_PID 2>/dev/null
        exit 1
    fi
    sleep 5
done

# Login to ArgoCD
echo "Logging into ArgoCD..."
argocd login --insecure --username admin --password $PASS --grpc-web $BASE_HOST

# Update password
echo "Updating admin password..."
argocd account update-password \
    --current-password $PASS \
    --new-password Admin123 \
    --grpc-web

# Install metrics server
echo "Installing metrics server..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Login with new password
echo "Logging in with new password..."
argocd login --insecure --username admin --password Admin123 --grpc-web $BASE_HOST

# Apply ArgoCD application
echo "Applying ArgoCD application configuration..."
kubectl apply -f argocd-components-app.yaml

echo "Installation complete!"
echo "You can now access ArgoCD UI at: https://$BASE_HOST"
echo "Username: admin"
echo "Password: Admin123"