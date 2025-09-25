# Stage 1: Build the application using a PHP base to ensure OS consistency.
FROM php:8.3-fpm-bookworm AS builder

# Set the working directory for the build.
WORKDIR /app

# Install system dependencies needed for Composer and its plugins.
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev

# Install the required PHP extensions.
RUN docker-php-ext-configure gd --with-jpeg --with-webp
RUN docker-php-ext-install -j$(nproc) gd zip

# Install Composer globally.
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Run create-project to download the Drupal CMS project and its dependencies.
RUN composer create-project drupal/cms .

# After creating the project, immediately update all dependencies to their
# latest possible versions according to the composer.json constraints.
RUN composer update

# After the project is created, add any additional modules you need.
RUN composer require \
    'drupal/samlauth:^3.11' \
    'drush/drush:^13.6'

# ---

# Stage 2: Build the production environment base. This is kept separate for clarity and caching.
FROM php:8.3-fpm-bookworm AS drupal_app_base

# Set environment variables for the application.
ENV PATH="/app/vendor/bin:$PATH"

# Install system dependencies. Note: 'git' is not needed in the final image.
RUN apt-get update && apt-get install -y \
    unzip \
    rsync \
    libzip-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libpq-dev \
    nginx

# Configure and install required PHP extensions for Drupal.
RUN docker-php-ext-configure gd --with-jpeg --with-webp
RUN docker-php-ext-install -j$(nproc) gd zip pdo pdo_pgsql opcache

# Set up the application directory.
WORKDIR /app

# ---

# Stage 3: Build the final image.
FROM drupal_app_base AS final

# Copy the fully built Drupal application from the 'builder' stage.
COPY --from=builder /app .

# Copy your custom Nginx configuration and entrypoint script.
COPY .docker/nginx/default.conf /etc/nginx/sites-available/default
COPY .docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY .docker/drupal/settings.local.php /app/settings.local.php
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set ownership to the web user to avoid permission issues.
RUN chown -R www-data:www-data /app/web/sites

# Expose port 80 for the Nginx web server.
EXPOSE 80

# The entrypoint script will start PHP-FPM and Nginx.
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]