param(
    [string]$Namespace = "laravel-app"
)

Write-Host "Cleaning up deployment..." -ForegroundColor Yellow

kubectl delete namespace $Namespace 2>&1 | Out-Null

# Remove Docker images
docker rmi laravel-app:latest 2>&1 | Out-Null

Write-Host "Cleanup completed!" -ForegroundColor Green