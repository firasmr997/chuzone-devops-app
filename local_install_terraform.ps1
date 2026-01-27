$ErrorActionPreference = "Stop"
$terraformVersion = "1.5.7" # Using a recent stable version
$installDir = "$PSScriptRoot\bin"
$zipPath = "$installDir\terraform.zip"
$url = "https://releases.hashicorp.com/terraform/$terraformVersion/terraform_${terraformVersion}_windows_amd64.zip"

Write-Host ">>> Setting up local Terraform..." -ForegroundColor Cyan
if (-not (Test-Path $installDir)) {
    New-Item -ItemType Directory -Path $installDir | Out-Null
}

if (-not (Test-Path "$installDir\terraform.exe")) {
    Write-Host "Downloading Terraform from $url..."
    Invoke-WebRequest -Uri $url -OutFile $zipPath
    
    Write-Host "Extracting..."
    Expand-Archive -Path $zipPath -DestinationPath $installDir -Force
    Remove-Item $zipPath
}

Write-Host ">>> Terraform installed at $installDir"
$env:PATH = "$installDir;$env:PATH"
terraform version
