# Build locally (trusted machine) and upload the artifacts to the EC2 server.
# Usage (PowerShell, from the repository root):
#   .\deploy\deploy.ps1            # build + upload only
#   .\deploy\deploy.ps1 -Install   # build + upload + run server-deploy.sh
param(
  [string]$Key = "C:\Llave.pem",
  [string]$ServerHost = "ec2-user@3.85.202.14",
  [switch]$Install
)
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$stage = Join-Path $env:TEMP "enterprise-risk-deploy"

# Backend
Push-Location (Join-Path $root "backend")
.\mvnw.cmd -q clean package
if ($LASTEXITCODE -ne 0) { throw "backend build failed" }
Pop-Location

# Frontend (uses .env.production -> VITE_API_URL=https://team4-risk.duckdns.org)
Push-Location (Join-Path $root "frontend")
npm ci
npm run build
if ($LASTEXITCODE -ne 0) { throw "frontend build failed" }
Pop-Location

# Stage files
if (Test-Path $stage) { Remove-Item -Recurse -Force $stage }
New-Item -ItemType Directory -Force $stage | Out-Null
Copy-Item (Join-Path $root "backend\target\enterprise-risk-api.jar") (Join-Path $stage "app.jar")
Copy-Item -Recurse (Join-Path $root "frontend\dist") (Join-Path $stage "dist")
Copy-Item (Join-Path $PSScriptRoot "enterprise-risk-api.service"), `
          (Join-Path $PSScriptRoot "enterprise-risk.conf"), `
          (Join-Path $PSScriptRoot "server-*.sh") $stage

# Upload over SSH
ssh -i $Key $ServerHost "rm -rf ~/deploy && mkdir -p ~/deploy"
scp -i $Key -r "$stage\*" "${ServerHost}:~/deploy/"
if ($LASTEXITCODE -ne 0) { throw "upload failed" }

if ($Install) {
  ssh -i $Key $ServerHost "sudo bash ~/deploy/server-deploy.sh"
}
