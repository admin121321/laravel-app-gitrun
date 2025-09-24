FROM php:8.3.26RC1-fpm-alpine3.21

FROM node:22.11-alpine

# Install system dependencies
RUN apk update && apk add --no-cache \
    nginx \
    nodejs \
    npm \
    git \
    curl \
    zip \
    unzip

# Install PHP extensions untuk Laravel
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    mbstring \
    tokenizer \
    xml \
    ctype \
    json \
    bcmath


# Install Composer
RUN apt-get update && apt-get install -y \
    unzip git curl && \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install dependencies (tanpa dev untuk production)
RUN composer install --optimize-autoloader --no-dev

RUN composer self-update

RUN composer clear-cache

WORKDIR /var/www

# Install system dependencies
RUN apt update && apt install -y \
    git \
    curl \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    zip \
    unzip \
    nginx \
    supervisor \
    default-mysql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /var/www/

WORKDIR /var/www/

# Copy package files first
COPY package*.json ./


# Clean cache thoroughly sebelum install
RUN npm cache clean --force && \
    npm install


# Copy application
COPY . .

# Setup permissions
RUN chown -R www-data:www-data /var/www/storage \
    && chown -R www-data:www-data /var/www/bootstrap/cache \
    && chmod -R 775 /var/www/storage \
    && chmod -R 775 /var/www/bootstrap/cache

# Copy configurations
COPY docker/nginx.conf /etc/nginx/sites-available/default
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php.ini /usr/local/etc/php/local.ini

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

# Use supervisor to manage processes
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf","php-fpm"]

# Health check untuk container
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /usr/local/bin/health-check.sh