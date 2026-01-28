# restart_services.ps1
# Restarts containerd and kubelet on all nodes to fix 'FailedCreatePodSandBox' or certificate errors.

$User = "ubuntu"
$KeyPath = "$HOME\.ssh\id_rsa"

# REAL IPs
$MasterIP = "54.149.133.186"
$Worker1IP = "54.202.218.151"
$Worker2IP = "16.148.94.162"

$Cmd = "sudo systemctl restart containerd kubelet"

Write-Host ">>> Restarting services on Master ($MasterIP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$MasterIP $Cmd

Write-Host ">>> Restarting services on Worker 1 ($Worker1IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker1IP $Cmd

Write-Host ">>> Restarting services on Worker 2 ($Worker2IP)..." -ForegroundColor Cyan
ssh -o StrictHostKeyChecking=no -i $KeyPath $User@$Worker2IP $Cmd

Write-Host ">>> Services Restarted!" -ForegroundColor Green
