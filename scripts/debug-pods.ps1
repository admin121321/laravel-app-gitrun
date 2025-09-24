param(
    [string]$Namespace = "laravel-app"
)

Write-Host "🔍 Debugging Laravel Pods" -ForegroundColor Cyan

# Get all pods in namespace
Write-Host "`n=== All Pods ===" -ForegroundColor Green
kubectl get pods -n $Namespace -o wide

# Get Laravel pods details
Write-Host "`n=== Laravel Pods Details ===" -ForegroundColor Green
$laravelPods = kubectl get pods -n $Namespace -l app=laravel-app -o jsonpath='{.items[*].metadata.name}'
foreach ($pod in $laravelPods.Split(' ')) {
    if ($pod) {
        Write-Host "`n--- Pod: $pod ---" -ForegroundColor Yellow
        
        # Pod status
        Write-Host "Status:" -ForegroundColor Gray
        kubectl get pod $pod -n $Namespace -o jsonpath='{range .status.conditions[*]}{.type}={.status} {.message}{"\n"}{end}'
        
        # Pod events
        Write-Host "Events:" -ForegroundColor Gray
        kubectl describe pod $pod -n $Namespace | Select-String -Pattern "Events:" -Context 0,10
        
        # Container status
        Write-Host "Container Status:" -ForegroundColor Gray
        kubectl get pod $pod -n $Namespace -o jsonpath='{.status.containerStatuses[*].name}{"\t"}{.status.containerStatuses[*].ready}{"\t"}{.status.containerStatuses[*].state}{"\n"}'
        
        # Logs (last 10 lines)
        Write-Host "Logs (last 20 lines):" -ForegroundColor Gray
        kubectl logs $pod -n $Namespace --tail=20
    }
}

# Check services
Write-Host "`n=== Services ===" -ForegroundColor Green
kubectl get svc -n $Namespace

# Check ingress
Write-Host "`n=== Ingress ===" -ForegroundColor Green
kubectl get ingress -n $Namespace

# Check persistent volumes
Write-Host "`n=== Persistent Volumes ===" -ForegroundColor Green
kubectl get pvc -n $Namespace