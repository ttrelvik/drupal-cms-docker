#!/bin/bash
set -e

# DIRECTORY WHERE BACKUPS WILL BE STORED
# Make sure to change this to your desired backup location.
BACKUP_DIR="./backups/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"

echo "Starting backup..."

# --- MAINTENANCE MODE: ON ---
echo "Enabling maintenance mode..."
docker compose exec drupal_cms vendor/bin/drush sset system.maintenance_mode 1

# TRAP to ensure maintenance mode is turned off, even if the script fails
trap 'echo "An error occurred. Disabling maintenance mode..."; docker compose exec drupal_cms vendor/bin/drush sset system.maintenance_mode 0; exit 1' ERR

# --- CORE BACKUP LOGIC ---
# 1. BACK UP THE DATABASE
echo "Dumping database..."
docker compose exec -T db pg_dump -U drupal -d drupal > "$BACKUP_DIR/db.sql"

# 2. BACK UP THE FILES
echo "Archiving files..."
docker run --rm \
  -v "$(basename "$(pwd)")_drupal_sites_default":/volume \
  -v "$BACKUP_DIR":/backup \
  alpine tar -czf /backup/files.tar.gz -C /volume .

# --- MAINTENANCE MODE: OFF ---
echo "Disabling maintenance mode..."
docker compose exec drupal_cms vendor/bin/drush sset system.maintenance_mode 0

# --- CLEANUP ---
# Remove the trap now that the script has completed successfully
trap - ERR

echo "Backup complete! Files are in: $BACKUP_DIR"