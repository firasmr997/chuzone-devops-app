# clean_cni.ps1
# Removes conflicting CNI configurations (Calico) to allow Flannel to work.

$User = "ubuntu"
$KeyPath = "$HOME\.ssh\id_rsa"

# REAL IPs
$MasterIP = "54.149.133.186"
$Worker1IP = "54.202.218.151"
$Worker2IP = "16.148.94.162"

$Cmd = "sudo rm -rf /etc/cni/net.d/* && sudo systemctl restart containerd kubelet"

Write-Host ">>> Cleaning CNI on Master ($MasterIP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$MasterIP $Cmd

Write-Host ">>> Cleaning CNI on Worker 1 ($Worker1IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker1IP $Cmd

Write-Host ">>> Cleaning CNI on Worker 2 ($Worker2IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker2IP $Cmd

Write-Host ">>> CNI Cleaned & Services Restarted!" -ForegroundColor Green
