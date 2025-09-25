#!/bin/sh
set -e

# Define paths
SITES_DEFAULT_DIR="/app/web/sites/default"
LOCAL_SETTINGS_SOURCE="/app/settings.local.php"
LOCAL_SETTINGS_DEST="$SITES_DEFAULT_DIR/settings.local.php"

# Copy local settings file if it exists in the image.
# This ensures custom settings are applied on every container start.
if [ -f "$LOCAL_SETTINGS_SOURCE" ]; then
  echo "Entrypoint: Copying settings.local.php..."
  cp "$LOCAL_SETTINGS_SOURCE" "$LOCAL_SETTINGS_DEST"
fi

echo "Entrypoint: Applying ownership to the sites/default directory..."
# FIX: Only run chown on the volume mount for a fast startup.
chown -R www-data:www-data /app/web/sites/default

echo "Entrypoint: Starting PHP-FPM in the background..."
# Start PHP-FPM as a daemon so the script can continue.
php-fpm -D

echo "Entrypoint: Starting Nginx in the foreground..."
# BEST PRACTICE: exec replaces the shell with nginx, making it PID 1.
exec nginx -g 'daemon off;'