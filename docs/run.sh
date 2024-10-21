argocd app create argocd-components \
  --repo https://github.com/MiletoCarmelo/DEVOPS_ARGOCD.git \
  --path argocd-components \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated

# => application 'argocd-components' created

helm template -f ./argocd-components/Chart.yaml argocd-components ./argocd-components/
helm upgrade -i -f ./argocd-components/Chart.yaml argocd-components ./argocd-components/


argocd app create trading-strategy-analysis-dev \
  --repo https://github.com/MiletoCarmelo/DEVOPS_DEPLOY_TradingStrategyAnaylsis.git \
  --path umbrella-trading-strategy-analysis \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --sync-policy automated \
  --project quant-cm \
  --values values.dev.yaml

argocd app create trading-strategy-analysis-prod \
  --repo https://github.com/MiletoCarmelo/DEVOPS_DEPLOY_TradingStrategyAnaylsis.git \
  --path umbrella-trading-strategy-analysis \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod \
  --sync-policy automated \
  --project quant-cm \
  --values values.prod.yaml