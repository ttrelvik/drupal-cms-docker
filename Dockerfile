# Stage 1: Build the base with PHP and required extensions
# We use the official PHP image for Debian Bookworm to align with DDEV's environment.
FROM php:8.3-fpm-bookworm AS drupal_cms_base

# Set environment variables
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    PATH="/app/vendor/bin:$PATH"

# Install system dependencies needed for Drupal and common PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    rsync \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libpq-dev \
    nginx

# Install required PHP extensions for Drupal
RUN docker-php-ext-configure gd --with-jpeg --with-webp
RUN docker-php-ext-install -j$(nproc) gd zip pdo pdo_pgsql opcache

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set up the application directory
WORKDIR /app

# ---
# Stage 2: Build the final image with application code
FROM drupal_cms_base AS final

# Copy the entire project (including the 'web' directory) into the image
COPY . .

# Copy the Nginx configuration
COPY .docker/nginx/default.conf /etc/nginx/sites-available/default

# Copy the entrypoint script and make it executable
COPY .docker/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set ownership to the web user to avoid permission issues
RUN chown -R www-data:www-data /app

# Expose port 80 for Nginx
EXPOSE 80

# Set the entrypoint
ENTRYPOINT ["entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]