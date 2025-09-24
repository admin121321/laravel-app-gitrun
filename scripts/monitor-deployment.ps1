param(
    [string]$Namespace = "laravel-app",
    [int]$Timeout = 600
)

Write-Host "🔍 Real-time Deployment Monitor" -ForegroundColor Cyan
Write-Host "Timeout: $Timeout seconds" -ForegroundColor Yellow

$startTime = Get-Date
$endTime = $startTime.AddSeconds($Timeout)

while ((Get-Date) -lt $endTime) {
    Clear-Host
    Write-Host "🕒 $(Get-Date -Format 'HH:mm:ss') - Monitoring..." -ForegroundColor Cyan
    
    # Get all pods
    Write-Host "`n=== Pods Status ===" -ForegroundColor Green
    kubectl get pods -n $Namespace -o wide
    
    # Get Laravel pods details
    Write-Host "`n=== Laravel Pods Details ===" -ForegroundColor Yellow
    $pods = kubectl get pods -n $Namespace -l app=laravel-app -o jsonpath='{.items[*].metadata.name}'
    
    foreach ($pod in $pods.Split(' ')) {
        if ($pod) {
            Write-Host "`n--- $pod ---" -ForegroundColor White
            $status = kubectl get pod $pod -n $Namespace -o jsonpath='{.status.phase}'
            $ready = kubectl get pod $pod -n $Namespace -o jsonpath='{.status.containerStatuses[0].ready}'
            Write-Host "Status: $status, Ready: $ready" -ForegroundColor Gray
            
            # Show recent events
            $events = kubectl get events -n $Namespace --field-selector involvedObject.name=$pod --sort-by='.lastTimestamp' -o wide | Select-Object -Last 3
            if ($events) {
                Write-Host "Recent Events:" -ForegroundColor DarkGray
                $events | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
            }
            
            # Show last few log lines if pod is running
            if ($status -eq "Running") {
                try {
                    $logs = kubectl logs $pod -n $Namespace --tail=5 2>&1
                    Write-Host "Last 5 logs:" -ForegroundColor DarkGray
                    $logs | ForEach-Object { Write-Host "  $_" -ForegroundColor DarkGray }
                } catch {
                    Write-Host "  Could not fetch logs" -ForegroundColor DarkRed
                }
            }
        }
    }
    
    # Check if all pods are ready
    $allReady = $true
    foreach ($pod in $pods.Split(' ')) {
        if ($pod) {
            $ready = kubectl get pod $pod -n $Namespace -o jsonpath='{.status.containerStatuses[0].ready}'
            if ($ready -ne "true") {
                $allReady = $false
                break
            }
        }
    }
    
    if ($allReady -and $pods) {
        Write-Host "`n🎉 All pods are ready!" -ForegroundColor Green
        break
    }
    
    $elapsed = (Get-Date) - $startTime
    Write-Host "`n⏳ Elapsed: $([math]::Round($elapsed.TotalSeconds))s | Remaining: $([math]::Round(($endTime - (Get-Date)).TotalSeconds))s" -ForegroundColor Cyan
    Start-Sleep -Seconds 10
}

if ((Get-Date) -ge $endTime) {
    Write-Host "❌ Timeout reached! Pods did not become ready in time." -ForegroundColor Red
    Write-Host "`n=== Final Debug Information ===" -ForegroundColor Red
    kubectl describe pods -n $Namespace -l app=laravel-app
}