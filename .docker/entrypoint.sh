#!/bin/sh
set -e

# Start PHP-FPM in the background
php-fpm &

# Execute the command passed to the script (e.g., nginx)
exec "$@"