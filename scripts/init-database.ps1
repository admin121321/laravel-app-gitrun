param(
    [string]$Namespace = "laravel-app",
    [string]$MysqlPassword = "rootpassword"
)

Write-Host "Initializing database..." -ForegroundColor Cyan

# Wait for MySQL to be fully ready
Write-Host "Waiting for MySQL to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=mysql -n $Namespace --timeout=300s

# Additional wait for MySQL service to be fully operational
Start-Sleep -Seconds 20

# Create MySQL configuration file to avoid password warning
$tempConfig = "C:\temp\my.cnf"
$configContent = @"
[client]
user=root
password=$MysqlPassword
host=mysql-service.$Namespace.svc.cluster.local
"@

# Ensure directory exists
New-Item -ItemType Directory -Force -Path (Split-Path $tempConfig)
$configContent | Out-File -FilePath $tempConfig -Encoding ASCII

try {
    # Test MySQL connection
    Write-Host "Testing MySQL connection..." -ForegroundColor Yellow
    kubectl exec deployment/mysql -n $Namespace -- mysql --defaults-file=/tmp/my.cnf -e "SELECT 1;" 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ MySQL connection successful!" -ForegroundColor Green
    } else {
        Write-Host "❌ MySQL connection failed" -ForegroundColor Red
        exit 1
    }

    # Create database and user using configuration file
    Write-Host "Creating database and user..." -ForegroundColor Yellow
    
    $sqlCommands = @"
CREATE DATABASE IF NOT EXISTS laravel_db;
CREATE USER IF NOT EXISTS 'laravel_user'@'%' IDENTIFIED BY 'laravel_password';
GRANT ALL PRIVILEGES ON laravel_db.* TO 'laravel_user'@'%';
FLUSH PRIVILEGES;
SHOW DATABASES;
SELECT user, host FROM mysql.user WHERE user = 'laravel_user';
"@

    # Save SQL commands to a file and execute
    $tempSqlFile = "C:\temp\init.sql"
    $sqlCommands | Out-File -FilePath $tempSqlFile -Encoding ASCII

    # Copy files to pod and execute
    kubectl cp $tempConfig ${Namespace}/$(kubectl get pod -n $Namespace -l app=mysql -o jsonpath='{.items[0].metadata.name}'):/tmp/my.cnf
    kubectl cp $tempSqlFile ${Namespace}/$(kubectl get pod -n $Namespace -l app=mysql -o jsonpath='{.items[0].metadata.name}'):/tmp/init.sql
    
    kubectl exec deployment/mysql -n $Namespace -- mysql --defaults-file=/tmp/my.cnf < /tmp/init.sql
    
    Write-Host "✅ Database initialization completed successfully!" -ForegroundColor Green
    
} catch {
    Write-Host "❌ Database initialization failed: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    # Cleanup temporary files
    Remove-Item $tempConfig -ErrorAction SilentlyContinue
    Remove-Item $tempSqlFile -ErrorAction SilentlyContinue
}