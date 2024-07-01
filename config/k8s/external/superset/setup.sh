helm repo add superset https://apache.github.io/superset
helm upgrade --install --values values.yaml --namespace superset --create-namespace superset superset/superset

