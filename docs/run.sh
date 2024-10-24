argocd app create argocd-components \
  --repo https://github.com/MiletoCarmelo/DEVOPS_ARGOCD.git \
  --path argocd-components \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace argocd \
  --sync-policy automated

# => application 'argocd-components' created

helm template -f ./argocd-components/Chart.yaml argocd-components ./argocd-components/
helm upgrade -i -f ./argocd-components/Chart.yaml argocd-components ./argocd-components/


argocd app create tsa \
  --repo https://github.com/MiletoCarmelo/DEVOPS_DEPLOY_TradingStrategyAnaylsis.git \
  --path umbrella-trading-strategy-analysis \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --sync-policy automated \
  --project quant-cm \
  --values values.dev.yaml

argocd app create tsa \
  --repo https://github.com/MiletoCarmelo/DEVOPS_DEPLOY_TradingStrategyAnaylsis.git \
  --path umbrella-trading-strategy-analysis \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod \
  --sync-policy automated \
  --project quant-cm \
  --values values.prod.yaml


# toujours à comprendre pk il faut les créer manuellement car normalement ils sont créés automatiquement
# depuis le fichier argocd-components/values-prod.yaml et argocd-components/values-dev.yaml. 
# l'hypothèse est que ne les aie mal normé (manquant le "-dev" et "-prod", ou bien alors justement avec qui faut enlever)


# Créer l'application
argocd app create tsa-pod \
  --repo https://github.com/MiletoCarmelo/DEVOPS_DEPLOY_TradingStrategyAnaylsis.git \
  --path umbrella-trading-strategy-analysis-temp-pod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace dev \
  --sync-policy automated \
  --project quant-cm \
  --values values.dev.yaml

# Créer l'application
argocd app create tsa-pod \
  --repo  https://github.com/MiletoCarmelo/DEVOPS_DEPLOY_TradingStrategyAnaylsis.git \
  --path umbrella-trading-strategy-analysis-temp-pod \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace prod \
  --sync-policy automated \
  --project quant-cm \
  --values values.prod.yaml