param([string]$ClusterName = "gitops-pilot")
$ErrorActionPreference = "Stop"
foreach ($tool in @("docker", "kind", "kubectl", "helm")) {
  if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool is required but not installed." }
}
if (-not (kind get clusters | Select-String -SimpleMatch $ClusterName)) {
  kind create cluster --name $ClusterName --config kind-config.yaml
}
docker build --tag ghcr.io/srikanthmanikandan38/gitops-pilot:latest .
kind load docker-image ghcr.io/srikanthmanikandan38/gitops-pilot:latest --name $ClusterName
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f gitops/argocd/application.yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --values monitoring/kube-prometheus-stack-values.yaml --wait --timeout 10m
kubectl apply -f monitoring/alerts.yaml
$encodedPassword = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}'
$argoPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPassword))
Write-Host "Argo CD password: $argoPassword"
Write-Host "Dashboard: kubectl -n gitops-pilot port-forward service/gitops-pilot 3000:80"
Write-Host "Grafana: kubectl -n monitoring port-forward service/kube-prometheus-stack-grafana 3001:80"
