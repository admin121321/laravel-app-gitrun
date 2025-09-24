# setup-runner.ps1
$ErrorActionPreference = "Stop"

Write-Host "Setting up GitHub Self-Hosted Runner on Windows..." -ForegroundColor Green

# Create runner directory
$RunnerDir = "C:\actions-runner"
if (!(Test-Path $RunnerDir)) {
    New-Item -ItemType Directory -Path $RunnerDir -Force
}
Set-Location $RunnerDir

# Download runner
$RunnerUrl = "https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-win-x64-2.311.0.zip"
$ZipPath = "$RunnerDir\actions-runner.zip"

Write-Host "Downloading GitHub Runner..." -ForegroundColor Yellow
Invoke-WebRequest -Uri $RunnerUrl -OutFile $ZipPath

# Extract runner
Write-Host "Extracting runner..." -ForegroundColor Yellow
Expand-Archive -Path $ZipPath -DestinationPath $RunnerDir -Force
Remove-Item $ZipPath

# Configure runner (ganti dengan token dari GitHub)
Write-Host "Please configure the runner manually:" -ForegroundColor Cyan
Write-Host "1. Go to your GitHub repository" -ForegroundColor White
Write-Host "2. Settings -> Actions -> Runners -> New self-hosted runner" -ForegroundColor White
Write-Host "3. Follow Windows instructions" -ForegroundColor White

Write-Host "Setup completed! Run config.cmd to configure the runner." -ForegroundColor Green