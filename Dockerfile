

FROM php:8.3.26RC1-fpm-alpine3.21

FROM node:lts-alpine3.22

USER root  

# Install PHP dengan SEMUA extensions yang diperlukan Laravel
RUN apk update && apk add --no-cache \
    php83 \
    php83-fpm \
    php83-phar \
    php83-json \
    php83-mbstring \
    php83-tokenizer \
    php83-xml \
    php83-ctype \
    php83-curl \
    php83-openssl \
    php83-fileinfo \
    php83-dom \
    php83-iconv \
    php83-zip \
    php83-gd \
    php83-bcmath \
    php83-pdo \
    php83-pdo_mysql \
    php83-session \
    php83-simplexml \
    nginx \
    nodejs \
    git \
    npm \
    composer \
    curl \
    unzip \
    libpng-dev \
    libzip-dev \
    oniguruma-dev \
    supervisor

# BUAT DIRECTORY UNTUK PHP-FPM SOCKET SEBELUM COPY APLIKASI
#RUN mkdir -p /var/run/php
#RUN chown -R nobody:nobody /var/run/php
#RUN chmod -R 775 /var/run/php

RUN mkdir -p /var/www/

WORKDIR /var/www/

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy application
COPY . .

# Copy supervisord configuration
# Debug: Cek supervisord installation
#RUN echo "=== SUPERVISORD DEBUG ==="
#RUN which supervisord
#RUN ls -la /usr/bin/supervisord
#RUN supervisord --version

# Cek directory structure
#RUN mkdir -p /etc/supervisor/conf.d
#RUN ls -la /etc/supervisor/

#COPY /docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Verifikasi file artisan ada
RUN ls -la artisan || echo "artisan file not found!"

# Hapus vendor directory jika ada (dari host)
RUN rm -rf vendor/

RUN composer install --optimize-autoloader --no-dev --prefer-dist

# Clean cache thoroughly sebelum install
RUN npm cache clean --force && \
    npm install

RUN composer self-update

RUN composer clear-cache

# Copy PHP-FPM configuration
COPY docker/www.conf /usr/local/etc/php-fpm.d/www.conf
#COPY docker/php-fpm.conf /etc/php83/php-fpm.d/www.conf

# Gunakan user nobody (default Alpine user)
RUN chown -R nobody:nobody /var/www/
RUN chown -R nobody:nobody /var/www/storage
RUN chown -R nobody:nobody /var/www/bootstrap/cache
RUN chmod +rwx /var/www/
RUN chmod -R 777 /var/www/

# Copy configurations
# Copy fixed nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/php.ini /usr/local/etc/php/local.ini
#COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Health check script
#COPY docker/health-check.sh /usr/local/bin/health-check.sh
#RUN chmod +x /usr/local/bin/health-check.sh

# Setup Nginx dan PHP-FPM directories
RUN mkdir -p /var/log/nginx /var/lib/nginx
RUN mkdir -p /run/nginx

# Generate key (will be overridden by env)
#RUN php artisan key:generate --no-ansi

# Buat startup script yang robust
#COPY docker/start.sh /start.sh
#RUN chmod +x /start.sh

# Optimize Laravel
RUN php83 artisan config:cache
RUN php83 artisan route:cache

RUN npm run build  

EXPOSE 80

RUN ["chmod", "+x", "post_deploy.sh"]
CMD [ "sh", "post_deploy.sh" ]
# Use supervisor to manage processes
#CMD ["php83", "-S", "0.0.0.0:80", "-t", "public"]
#CMD ["/start.sh"]


# Health check untuk container
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/health-check.sh