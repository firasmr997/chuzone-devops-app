# remove_calico_cni.ps1
# Removes specific Calico CNI configuration files that conflict with Flannel.

$User = "ubuntu"
$KeyPath = "$HOME\.ssh\id_rsa"

# REAL IPs
$MasterIP = "54.149.133.186"
$Worker1IP = "54.202.218.151"
$Worker2IP = "16.148.94.162"

$Cmd = "sudo rm -f /etc/cni/net.d/10-calico.conflist /etc/cni/net.d/calico-kubeconfig && sudo systemctl restart containerd kubelet"

Write-Host ">>> Removing Calico CNI from Master ($MasterIP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$MasterIP $Cmd

Write-Host ">>> Removing Calico CNI from Worker 1 ($Worker1IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker1IP $Cmd

Write-Host ">>> Removing Calico CNI from Worker 2 ($Worker2IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker2IP $Cmd

Write-Host ">>> Calico CNI Removed & Services Restarted!" -ForegroundColor Green
