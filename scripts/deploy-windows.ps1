param(
    [string]$Namespace = "laravel-app",
    [string]$ImageTag = "latest"
)

Write-Host "🚀 Starting Windows Kubernetes Deployment..." -ForegroundColor Green

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow
$prereqs = @("docker", "kubectl")
foreach ($cmd in $prereqs) {
    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
        Write-Host "✓ $cmd is available" -ForegroundColor Green
    } else {
        Write-Host "✗ $cmd is not available" -ForegroundColor Red
        exit 1
    }
}

# Build Docker image
Write-Host "Building Docker image..." -ForegroundColor Yellow
docker build -t laravel-app:$ImageTag .

# Deploy to Kubernetes
Write-Host "Deploying to Kubernetes..." -ForegroundColor Yellow
kubectl apply -f kubernetes/ -n $Namespace

# Wait for deployment
Write-Host "Waiting for deployment to complete..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=laravel-app -n $Namespace --timeout=300s

# Port forward for testing
Write-Host "Starting port forwarding..." -ForegroundColor Yellow
$portForwardJob = Start-Job -ScriptBlock {
    param($Namespace)
    kubectl port-forward -n $Namespace service/laravel-service 8080:80
} -ArgumentList $Namespace

# Test application
Start-Sleep -Seconds 10
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8080" -TimeoutSec 30
    Write-Host "✅ Application is running successfully!" -ForegroundColor Green
} catch {
    Write-Host "❌ Application test failed: $($_.Exception.Message)" -ForegroundColor Red
}

# Cleanup
$portForwardJob | Stop-Job | Remove-Job

Write-Host "Deployment completed! Use 'kubectl get all -n $Namespace' to check status." -ForegroundColor Green