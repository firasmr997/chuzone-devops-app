# fix_cluster.ps1
# Manually initializes the Kubernetes cluster on the existing AWS instances.
# Updated with valid IPs as of today.

$User = "ubuntu"
$KeyPath = "$HOME\.ssh\id_rsa"

# REAL IPs from Terraform Output
$MasterIP = "54.149.133.186"
$Worker1IP = "54.202.218.151"
$Worker2IP = "16.148.94.162"

Write-Host ">>> Resetting & Initializing Master Node ($MasterIP)..." -ForegroundColor Cyan
# Added kubeadm reset to handle cases where it was previously initialized or IPs changed
$InitCmd = "sudo kubeadm reset -f && sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=NumCPU"
$SetupKubeconfig = "mkdir -p `$HOME/.kube && sudo cp -f /etc/kubernetes/admin.conf `$HOME/.kube/config && sudo chown `$(id -u):`$(id -g) `$HOME/.kube/config"
$InstallFlannel = "kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml"
$GetJoinCmd = "kubeadm token create --print-join-command"

# SSH into Master and Run
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$MasterIP "$InitCmd && $SetupKubeconfig && $InstallFlannel"

Write-Host ">>> Retrieving Join Token..." -ForegroundColor Cyan
$JoinCommand = ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$MasterIP "$GetJoinCmd"
Write-Host "Join Command: $JoinCommand" -ForegroundColor Yellow

$JoinCommandSudo = "sudo kubeadm reset -f && sudo $JoinCommand"

Write-Host ">>> Joining Worker 1 ($Worker1IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker1IP "$JoinCommandSudo"

Write-Host ">>> Joining Worker 2 ($Worker2IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker2IP "$JoinCommandSudo"

Write-Host ">>> Cluster Bootstrapped!" -ForegroundColor Green
Write-Host "Updating local kubeconfig..."
scp -o StrictHostKeyChecking=no -i $KeyPath $User@${MasterIP}:~/.kube/config $HOME/.kube/config
Write-Host "Done! Try 'kubectl get nodes' now."
