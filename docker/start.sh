#!/bin/sh

set -e  # Exit on any error

echo "=== Starting Laravel Application ==="

# Buat directory untuk PHP-FPM socket
mkdir -p /var/run/php
chown -R nobody:nobody /var/run/php
chmod -R 775 /var/run/php

# Gunakan TCP socket untuk menghindari permission issues
cat > /etc/php83/php-fpm.d/www.conf << 'EOF'
[www]
user = nobody
group = nobody
listen = 127.0.0.1:9000
listen.owner = nobody
listen.group = nobody
pm = dynamic
pm.max_children = 5
pm.start_servers = 2
pm.min_spare_servers = 1
pm.max_spare_servers = 3
pm.status_path = /status
ping.path = /ping
EOF

# Buat nginx config
cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name localhost;
        root /var/www/public;
        index index.php index.html;

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            try_files $uri =404;
            fastcgi_split_path_info ^(.+\.php)(/.+)$;
            fastcgi_pass 127.0.0.1:9000;
            fastcgi_index index.php;
            fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include fastcgi_params;
        }
    }
}
EOF

# Test PHP-FPM configuration
echo "Testing PHP-FPM configuration..."
php-fpm83 -t

# Start PHP-FPM
echo "Starting PHP-FPM..."
php-fpm83 -D

# Tunggu dan pastikan PHP-FPM berjalan
sleep 3

# Cek jika PHP-FPM process berjalan
if ! pgrep "php-fpm83" > /dev/null; then
    echo "❌ ERROR: PHP-FPM failed to start"
    ps aux
    exit 1
fi

# Test koneksi ke PHP-FPM
echo "Testing connection to PHP-FPM..."
if nc -z 127.0.0.1 9000; then
    echo "✅ PHP-FPM is running on port 9000"
else
    echo "❌ ERROR: Cannot connect to PHP-FPM on port 9000"
    netstat -tulpn || ss -tulpn
    exit 1
fi

# Test PHP-FPM status
echo "Testing PHP-FPM status..."
if curl -s http://127.0.0.1:9000/ping | grep -q pong; then
    echo "✅ PHP-FPM status check passed"
else
    echo "❌ PHP-FPM status check failed"
fi

# Test Laravel application
echo "Testing Laravel application..."
if php83 artisan --version; then
    echo "✅ Laravel artisan command works"
else
    echo "❌ Laravel artisan command failed"
fi

# Start Nginx
echo "Starting Nginx..."
echo "✅ Application is ready! Access via http://localhost:8000"
exec nginx -g 'daemon off;'