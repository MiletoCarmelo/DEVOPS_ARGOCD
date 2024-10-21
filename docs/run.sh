argocd app create argocd-components \
  --repo https://github.com/your-username/DEVOPS_ARGOCD.git \
  --path argocd-components \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated