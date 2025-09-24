#!/bin/sh

# update application cache
php artisan optimize

# start the application

php-fpm83 -D &&  nginx -g "daemon off;"