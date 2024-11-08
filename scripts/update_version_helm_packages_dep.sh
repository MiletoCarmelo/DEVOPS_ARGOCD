#!/bin/bash

# Chemin du fichier
VALUES_FILE="./argocd-components/values-dev.yaml"
BACKUP_FILE="${VALUES_FILE}.bak"

# Fonction pour obtenir la dernière version stable de cert-manager
get_cert_manager_version() {
    curl -s https://api.github.com/repos/cert-manager/cert-manager/releases/latest | grep tag_name | cut -d'"' -f4
}

# Fonction pour obtenir la dernière version stable de sealed-secrets
get_sealed_secrets_version() {
    curl -s https://api.github.com/repos/bitnami-labs/sealed-secrets/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/v//'
}

# Fonction pour obtenir la dernière version stable de ingress-nginx
get_ingress_nginx_version() {
    # Récupère la version sans le préfixe
    curl -s https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest | grep tag_name | cut -d'"' -f4 | sed 's/controller-//' | sed 's/helm-chart-//'
}

# Fonction pour mettre à jour le fichier values-dev.yaml
update_values_yaml() {
    local cert_manager_version=$1
    local sealed_secrets_version=$2
    local ingress_nginx_version=$3
    
    echo "Versions à appliquer :"
    echo "cert-manager: ${cert_manager_version}"
    echo "sealed-secrets: ${sealed_secrets_version}"
    echo "ingress-nginx: ${ingress_nginx_version}"
    
    # Faire une sauvegarde
    cp "$VALUES_FILE" "$BACKUP_FILE"
    
    # Mettre à jour les versions principales
    sed -i '' \
        -e "/cert-manager:/,/url:/ s/version: .*/version: ${cert_manager_version}/" \
        -e "/sealed-secrets:/,/url:/ s/version: .*/version: ${sealed_secrets_version}/" \
        -e "/ingress-nginx:/,/url:/ s/version: .*/version: ${ingress_nginx_version}/" \
        "$VALUES_FILE"
    
    # Mettre à jour les targetRevision
    sed -i '' \
        -e "/name: cert-manager/,/targetRevision:/ s/targetRevision: .*/targetRevision: ${cert_manager_version}/" \
        -e "/name: sealed-secrets/,/targetRevision:/ s/targetRevision: .*/targetRevision: ${sealed_secrets_version}/" \
        -e "/name: ingress-nginx/,/targetRevision:/ s/targetRevision: .*/targetRevision: ${ingress_nginx_version}/" \
        "$VALUES_FILE"
}

# Fonction pour afficher les différences
show_differences() {
    echo "Changements effectués :"
    diff "$BACKUP_FILE" "$VALUES_FILE" || true
}

# Fonction principale
main() {
    echo "Vérification des dernières versions stables..."
    
    # Vérifier que le fichier values-dev.yaml existe
    if [ ! -f "${VALUES_FILE}" ]; then
        echo "Erreur: ${VALUES_FILE} n'existe pas"
        exit 1
    fi
    
    # Récupérer les dernières versions
    CERT_MANAGER_VERSION=$(get_cert_manager_version)
    SEALED_SECRETS_VERSION=$(get_sealed_secrets_version)
    INGRESS_NGINX_VERSION=$(get_ingress_nginx_version)
    
    # Mettre à jour values-dev.yaml
    update_values_yaml "$CERT_MANAGER_VERSION" "$SEALED_SECRETS_VERSION" "$INGRESS_NGINX_VERSION"
    
    # Montrer les différences
    show_differences
    
    echo "Une sauvegarde a été créée dans ${BACKUP_FILE}"
}

# Exécution du script
main