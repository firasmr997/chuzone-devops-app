# setup_cluster.ps1
$ErrorActionPreference = "Stop"

# 1. Get IP Addresses from Terraform
Write-Host ">>> Getting Terraform Outputs..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot/infra"
$env:PATH = "$PSScriptRoot\bin;$env:PATH"
$masterIp = (terraform output -raw master_public_ip)
$worker1Ip = (terraform output -raw worker1_public_ip)
$worker2Ip = (terraform output -raw worker2_public_ip)
Set-Location "$PSScriptRoot"

Write-Host "Master IP: $masterIp"
Write-Host "Worker 1 IP: $worker1Ip"
Write-Host "Worker 2 IP: $worker2Ip"

$pemFile = "labsuser.pem"
$user = "ubuntu"

if (-not (Test-Path $pemFile)) {
    Write-Error "PEM file $pemFile not found!"
}

# Helper to run SSH command with Retry
function Run-SSH {
    param($ip, $cmd, $maxRetries = 20)
    $retryCount = 0
    while ($retryCount -lt $maxRetries) {
        try {
            $output = ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -i $pemFile $user@$ip $cmd 2>&1
            if ($LASTEXITCODE -eq 0) { return $output }
            Write-Host "SSH command failed (Attempt $($retryCount+1)/$maxRetries). Retrying..." -ForegroundColor DarkGray
        }
        catch {
            Write-Host "SSH Connectivity failed (Attempt $($retryCount+1)/$maxRetries)..." -ForegroundColor DarkGray
        }
        Start-Sleep -Seconds 10
        $retryCount++
    }
    Throw "Failed to execute SSH command on $ip after $maxRetries attempts."
}

# Wait for Kubeadm to be installed
function Wait-For-Kubeadm {
    param($ip)
    Write-Host "Waiting for kubeadm to be installed on $ip..." -ForegroundColor Cyan
    Run-SSH $ip "while [ ! -f /usr/bin/kubeadm ]; do echo 'Waiting for kubeadm...'; sleep 5; done"
}

# 2. Add Host to known_hosts to avoid manual interaction during script (Optional/Dangerous but useful for automation)
# Better: StrictHostKeyChecking=no is already in the command.

# Pre-check on all nodes
$nodes = @($masterIp, $worker1Ip, $worker2Ip)
foreach ($node in $nodes) {
    Wait-For-Kubeadm $node
}

# 3. Initialize Master
Write-Host ">>> Initializing Control Plane on Master..." -ForegroundColor Cyan
Run-SSH $masterIp "sudo kubeadm init --pod-network-cidr=192.168.0.0/16"

# 4. Configure kubectl on Master
Write-Host ">>> Configuring kubectl on Master..." -ForegroundColor Cyan
Run-SSH $masterIp "mkdir -p \$HOME/.kube && sudo cp -i /etc/kubernetes/admin.conf \$HOME/.kube/config && sudo chown \$(id -u):\$(id -g) \$HOME/.kube/config"

# 5. Install Calico CNI
Write-Host ">>> Installing Calico CNI..." -ForegroundColor Cyan
Run-SSH $masterIp "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/tigera-operator.yaml"
Run-SSH $masterIp "kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/custom-resources.yaml"

# 6. Get Join Command
Write-Host ">>> Getting Join Command..." -ForegroundColor Cyan
$joinCmd = Run-SSH $masterIp "kubeadm token create --print-join-command"
Write-Host "Join Command: $joinCmd" -ForegroundColor Yellow

# 7. Join Workers
Write-Host ">>> Joining Worker 1..." -ForegroundColor Cyan
Run-SSH $worker1Ip "sudo $joinCmd"

Write-Host ">>> Joining Worker 2..." -ForegroundColor Cyan
Run-SSH $worker2Ip "sudo $joinCmd"

Write-Host ">>> Cluster Setup Complete! Verifying nodes..." -ForegroundColor Green
Start-Sleep -Seconds 30
Run-SSH $masterIp "kubectl get nodes"
