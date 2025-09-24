# Run sebagai Administrator
Write-Host "Setting up GitHub Self-Hosted Runner on Windows..." -ForegroundColor Green

# Install Chocolatey (package manager)
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install dependencies
choco install docker-desktop -y
choco install kubernetes-cli -y
choco install kubelogin -y

# Start Docker Desktop
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

# Wait for Docker to start
Write-Host "Waiting for Docker to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Enable Kubernetes in Docker Desktop
$configPath = "$env:USERPROFILE\AppData\Roaming\Docker\settings.json"
$config = Get-Content $configPath | ConvertFrom-Json
$config.kubernetes.enabled = $true
$config | ConvertTo-Json -Depth 10 | Set-Content $configPath

# Restart Docker Desktop
Get-Process "Docker Desktop" -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Sleep -Seconds 10
Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"

Write-Host "Setup completed! Please configure Kubernetes in Docker Desktop GUI." -ForegroundColor Green