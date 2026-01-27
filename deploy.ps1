# Setup Local Path if exists
if (Test-Path "$PSScriptRoot\bin") {
    $env:PATH = "$PSScriptRoot\bin;$env:PATH"
}

# Check for AWS Credentials
if (-not $env:AWS_ACCESS_KEY_ID -and -not (Test-Path ~/.aws/credentials)) {
    Write-Warning "AWS Credentials not found!"
    $env:AWS_ACCESS_KEY_ID = Read-Host "Please enter AWS Access Key ID"
    $env:AWS_SECRET_ACCESS_KEY = Read-Host "Please enter AWS Secret Access Key"
    $env:AWS_SESSION_TOKEN = Read-Host "Please enter AWS Session Token (Optional)"
    $env:AWS_DEFAULT_REGION = "eu-west-3"
}

Write-Host ">>> Initializing Terraform..." -ForegroundColor Cyan
cd infra
terraform init

Write-Host ">>> Applying Terraform Plan..." -ForegroundColor Cyan
terraform apply -auto-approve

Write-Host ">>> Deployment Complete!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Wait a few minutes for the instances to boot."
Write-Host "2. Run setup_gitops.ps1 to verify connection and install apps."
