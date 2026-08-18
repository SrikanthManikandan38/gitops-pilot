param(
  [string]$Region = "ap-south-1",
  [string]$ClusterName = "gitops-pilot-development"
)
$ErrorActionPreference = "Stop"
foreach ($tool in @("aws", "terraform")) {
  if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) { throw "$tool is required but not installed." }
}
aws sts get-caller-identity | Out-Host
Push-Location terraform/bootstrap
terraform init
terraform apply
Pop-Location
Write-Host "Copy the output bucket name into terraform/backend.tf before continuing."
Write-Host "Then run: cd terraform; terraform init; terraform apply"
Write-Host "After Terraform finishes: aws eks update-kubeconfig --region $Region --name $ClusterName"
