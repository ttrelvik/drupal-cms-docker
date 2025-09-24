#!/bin/sh
set -e

echo "Entrypoint: Applying ownership to the sites/default directory..."
# FIX: Only run chown on the volume mount for a fast startup.
chown -R www-data:www-data /app/web/sites/default

echo "Entrypoint: Starting PHP-FPM in the background..."
# Start PHP-FPM as a daemon so the script can continue.
php-fpm -D

echo "Entrypoint: Starting Nginx in the foreground..."
# BEST PRACTICE: exec replaces the shell with nginx, making it PID 1.
exec nginx -g 'daemon off;'