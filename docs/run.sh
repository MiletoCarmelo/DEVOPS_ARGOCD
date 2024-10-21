argocd app create argocd-components \
  --repo https://github.com/MiletoCarmelo/DEVOPS_ARGOCD.git \
  --path argocd-components \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated

# => application 'argocd-components' created

helm template -i -f ./argocd-components/Chart.yaml argocd-components ./argocd-components/
helm upgrade -i -f ./argocd-components/Chart.yaml argocd-components ./argocd-components/
