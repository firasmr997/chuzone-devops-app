# setup_gitops.ps1
# Automates Phase 4: GitOps Deployment with ArgoCD
# Usage: ./setup_gitops.ps1

Write-Host ">>> API K8s Check..." -ForegroundColor Cyan
kubectl get nodes
if ($LASTEXITCODE -ne 0) {
    Write-Error "Cannot connect to Kubernetes. Make sure you have configured your kubeconfig (copied from Master)."
    exit 1
}

Write-Host ">>> Installing ArgoCD..." -ForegroundColor Cyan
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host ">>> Installing NGINX Ingress Controller..." -ForegroundColor Cyan
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.2/deploy/static/provider/cloud/deploy.yaml

Write-Host ">>> Applying ArgoCD Application..." -ForegroundColor Cyan
kubectl apply -f argocd-app.yaml

Write-Host ">>> Waiting for ArgoCD Server to start (might take a moment)..." -ForegroundColor Yellow
# Optional: Wait loop could be added here

Write-Host ">>> GitOps Setup Complete!" -ForegroundColor Green
Write-Host "To access your app:"
Write-Host "1. Update gitops/ingress.yaml with your DuckDNS domain."
Write-Host "2. Point your DuckDNS domain to one of the Worker Node Public IPs."
Write-Host "3. ArgoCD is running in namespace 'argocd'. Retrieve admin password:"
Write-Host "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($input))"
