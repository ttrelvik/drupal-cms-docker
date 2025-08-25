#!/bin/sh
set -e

chown -R www-data:www-data /app

# Start PHP-FPM in the background. Note: The command is 'php-fpm', not 'php-fpm8.3'.
php-fpm -D

# Create the Nginx log directory.
mkdir -p /var/log/nginx

# Symlink the Nginx logs to stdout/stderr for container logging.
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log

# Start Nginx in the foreground.
nginx -g 'daemon off;'