#!/bin/bash

# Health check script untuk Laravel
set -e

# Check if PHP-FPM is running
if ! pgrep "php-fpm" > /dev/null; then
    echo "PHP-FPM is not running"
    exit 1
fi

# Check if Nginx is running
if ! pgrep "nginx" > /dev/null; then
    echo "Nginx is not running"
    exit 1
fi

# Check if application responds
if curl -f http://localhost:8000 > /dev/null 2>&1; then
    echo "Application is healthy"
    exit 0
else
    echo "Application is not responding"
    exit 1
fi