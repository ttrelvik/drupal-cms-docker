#!/bin/bash
set -e

# --- CONFIGURATION ---
CONTAINER_FILTER="drupal_dev_drupal_cms_dev"
BACKUP_FILENAME="drupal-backup.tar.gz"
RESTORE_DEST_IN_CONTAINER="/tmp/$BACKUP_FILENAME"
EXTRACT_DIR="/tmp/restore_temp"

# --- SCRIPT START ---
if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <path_to_backup_directory>"
  echo "Example: ./restore.sh backups/2025-10-02_12-06-45"
  exit 1
fi

BACKUP_PATH="$1/$BACKUP_FILENAME"

if [ ! -f "$BACKUP_PATH" ]; then
  echo "Error: $BACKUP_FILENAME not found in $1"
  exit 1
fi

# --- HELPER FUNCTIONS ---
get_container_id() {
  local id
  id=$(docker ps -q --filter "name=${CONTAINER_FILTER}" | head -n 1)
  if [ -z "$id" ]; then
    echo "Error: Could not find a running container with filter '${CONTAINER_FILTER}'." >&2
    exit 1
  fi
  echo "$id"
}

run_in_container() {
  docker exec "$(get_container_id)" "$@"
}

# --- MAIN LOGIC ---
echo "Starting restore process for dev environment..."
CONTAINER_ID=$(get_container_id)

echo "Step 1: Preparing the Drupal site for restore..."
# This creates the settings.php file needed to connect to the database.
run_in_container cp /app/web/sites/default/default.settings.php /app/web/sites/default/settings.php
run_in_container chmod 664 /app/web/sites/default/settings.php

echo "Step 2: Copying backup archive into the container..."
docker cp "$BACKUP_PATH" "$CONTAINER_ID:$RESTORE_DEST_IN_CONTAINER"

echo "Step 3: Extracting the archive inside the container..."
run_in_container mkdir -p "$EXTRACT_DIR"
run_in_container tar -xzf "$RESTORE_DEST_IN_CONTAINER" -C "$EXTRACT_DIR"

echo "Step 4: Restoring the database..."
# First, drop all tables from the current (empty) database.
run_in_container vendor/bin/drush sql:drop -y
# Now, import the database from the backup file.
run_in_container vendor/bin/drush sql:cli < "$EXTRACT_DIR/database/database.sql"

echo "Step 5: Restoring the files..."
# Use rsync to copy the files into the correct location.
run_in_container rsync -a --delete "$EXTRACT_DIR/files/" /app/web/sites/default/files/

echo "Step 6: Cleaning up temporary files in container..."
run_in_container rm "$RESTORE_DEST_IN_CONTAINER"
run_in_container rm -rf "$EXTRACT_DIR"

echo "Step 7: Finalizing the site..."
# Run database updates and clear the cache.
run_in_container vendor/bin/drush updb -y
run_in_container vendor/bin/drush cr

echo "✅ Restore complete! Your site should now be a clone of the backup."