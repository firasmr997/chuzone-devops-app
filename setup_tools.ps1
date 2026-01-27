Write-Host ">>> Installing Terraform and AWS CLI..." -ForegroundColor Cyan

# Check for Administrator privileges and self-elevate if needed
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Requesting Administrator privileges..." -ForegroundColor Yellow
    $newProcess = Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs -PassThru
    exit
}

# Install using Chocolatey if available
if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Host "Using Chocolatey..."
    choco install terraform awscli -y
} 
# Fallback to Winget
elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    Write-Host "Using Winget..."
    winget install HashiCorp.Terraform -e
    winget install Amazon.AWSCLI -e
}
else {
    Write-Error "Neither Chocolatey nor Winget found. Please install Terraform and AWS CLI manually."
    exit 1
}

Write-Host ">>> Installation Complete! Please restart your terminal to update PATH." -ForegroundColor Green
