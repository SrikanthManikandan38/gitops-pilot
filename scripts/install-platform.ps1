param([string]$ClusterName = "gitops-pilot-development", [string]$Region = "ap-south-1")
$ErrorActionPreference = "Stop"
aws eks update-kubeconfig --region $Region --name $ClusterName
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl apply -f gitops/argocd/application.yaml
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install kube-prometheus-stack prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --values monitoring/kube-prometheus-stack-values.yaml
kubectl apply -f monitoring/alerts.yaml
Write-Host "Argo CD password: kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 --decode"
