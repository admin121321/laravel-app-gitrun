
FROM php:8.3.26RC1-fpm-alpine3.21

FROM node:22.11-alpine
  
# setup user as root
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
    oniguruma-dev

RUN ln -s /usr/bin/php83 /usr/bin/php
RUN ln -s /usr/sbin/php-fpm83 /usr/sbin/php-fpm

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

RUN mkdir -p /var/www/

WORKDIR /var/www/
# Copy application
COPY . .

# Copy supervisord configuration
COPY /docker/supervisord.conf /etc/supervisord.conf
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

# Gunakan user nobody (default Alpine user)
#RUN chown -R www-data:www-data /var/www/storage
#RUN chown -R www-data:www-data /var/www/bootstrap/cache
RUN chmod -R 775 /var/www/storage
RUN chmod -R 775 /var/www/bootstrap/cache

# Copy configurations
# Copy fixed nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf
#COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php.ini /usr/local/etc/php/local.ini

# Remove default.conf yang problematic
RUN rm -f /etc/nginx/conf.d/default.conf

# Health check script
COPY docker/health-check.sh /usr/local/bin/health-check.sh
RUN chmod +x /usr/local/bin/health-check.sh

# Setup Nginx dan PHP-FPM directories
RUN mkdir -p /var/log/nginx /var/lib/nginx
RUN mkdir -p /run/nginx

# Copy PHP-FPM configuration
COPY docker/www.conf /usr/local/etc/php-fpm.d/www.conf

# Generate key (will be overridden by env)
RUN php artisan key:generate --no-ansi


EXPOSE 9000

RUN ["chmod", "+x", "post_deploy.sh"]

# Use supervisor to manage processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

#CMD ["sh", "post_deploy.sh"]

# Health check untuk container
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/health-check.sh