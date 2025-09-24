param(
    [string]$Namespace = "laravel-app",
    [string]$MysqlPassword = "rootpassword"
)

Write-Host "Initializing database..." -ForegroundColor Cyan

function Write-Log {
    param([string]$Message, [string]$Color = "White")
    Write-Host "$(Get-Date -Format 'HH:mm:ss') - $Message" -ForegroundColor $Color
}

try {
    # Wait for MySQL to be ready
    Write-Log "Waiting for MySQL pod to be ready..." "Yellow"
    kubectl wait --for=condition=ready pod -l app=mysql -n $Namespace --timeout=300s
    Start-Sleep -Seconds 10

    # Get MySQL pod name
    $mysqlPod = kubectl get pod -n $Namespace -l app=mysql -o jsonpath='{.items[0].metadata.name}'
    Write-Log "MySQL pod: $mysqlPod" "White"

    # Test MySQL connection
    Write-Log "Testing MySQL connection..." "Yellow"
    $testResult = kubectl exec $mysqlPod -n $Namespace -- mysql -u root -p$MysqlPassword -e "SELECT 1;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Log "✅ MySQL connection successful!" "Green"
    } else {
        Write-Log "❌ MySQL connection failed: $testResult" "Red"
        exit 1
    }

    # SQL commands untuk initialize database
    $sqlCommands = @"
CREATE DATABASE IF NOT EXISTS laravel_db;
CREATE USER IF NOT EXISTS 'laravel_user'@'%' IDENTIFIED BY 'laravel_password';
GRANT ALL PRIVILEGES ON laravel_db.* TO 'laravel_user'@'%';
FLUSH PRIVILEGES;
SHOW DATABASES;
SELECT user, host FROM mysql.user WHERE user = 'laravel_user';
"@

    # Method 1: Gunakan echo dan pipe ke mysql
    Write-Log "Creating database and user..." "Yellow"
    
    # Escape quotes untuk PowerShell
    $escapedSql = $sqlCommands -replace '"', '\"'
    
    # Execute SQL commands menggunakan echo
    $command = "echo `"$escapedSql`" | mysql -u root -p$MysqlPassword"
    $result = kubectl exec $mysqlPod -n $Namespace -- bash -c $command
    
    Write-Log "SQL execution result: $result" "White"
    
    if ($LASTEXITCODE -eq 0) {
        Write-Log "✅ Database initialization completed successfully!" "Green"
    } else {
        Write-Log "❌ Database initialization failed" "Red"
        exit 1
    }

} catch {
    Write-Log "❌ Error: $($_.Exception.Message)" "Red"
    exit 1
}