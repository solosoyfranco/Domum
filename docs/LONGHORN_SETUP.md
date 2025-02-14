kubectl create ns longhorn-system

flux create source helm longhorn-repo \
  --url=https://charts.longhorn.io \
  --namespace=longhorn-system \
  --export > cluster/core/02-longhorn/helmrepo.yaml

kubectl apply -f cluster/core/02-longhorn/helmrepo.yaml

  flux create helmrelease longhorn-release \
  --chart=longhorn \
  --source=HelmRepository/longhorn-repo \
  --chart-version=v1.8.0 \
  --namespace=longhorn-system \
  --export > cluster/core/02-longhorn/helmrelease.yaml


  kubectl apply -f cluster/core/02-longhorn/helmrelease.yaml

flux get helmrelease longhorn-release -n longhorn-system
 kubectl -n longhorn-system get pod