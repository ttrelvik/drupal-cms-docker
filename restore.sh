#!/bin/bash
set -e

# --- CONFIGURATION ---
# IMPORTANT: This script targets the DEV container by default.
CONTAINER_FILTER="name=drupal_dev_drupal_cms_dev"
BACKUP_FILENAME="drupal-backup.tar.gz"
RESTORE_DEST_IN_CONTAINER="/tmp/$BACKUP_FILENAME"

# --- SCRIPT START ---
# Check if a backup path was provided.
if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <path_to_backup_directory>"
  echo "Example: ./restore.sh backups/2025-10-02_12-06-45"
  exit 1
fi

BACKUP_PATH="$1/$BACKUP_FILENAME"

if [ ! -f "$BACKUP_PATH" ]; then
  echo "Error: $BACKUP_FILENAME not found in $BACKUP_PATH"
  exit 1
fi

# --- HELPER FUNCTIONS ---
get_container_id() {
  local id
  # We target the dev stack, which is named 'drupal_dev'. The service is 'drupal_cms_dev'.
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

echo "Copying backup archive into the container..."
docker cp "$BACKUP_PATH" "$CONTAINER_ID:$RESTORE_DEST_IN_CONTAINER"

echo "Restoring database and files using drush archive:restore ..."
# The archive:restore command will drop all tables before restoring.
run_in_container vendor/bin/drush archive:restore "$RESTORE_DEST_IN_CONTAINER" --db --files -y

echo "Cleaning up temporary archive file in container..."
run_in_container rm "$RESTORE_DEST_IN_CONTAINER"

echo "Running database updates..."
run_in_container vendor/bin/drush updb -y

echo "Clearing caches..."
run_in_container vendor/bin/drush cr

echo "✅ Restore complete! Your dev site should now be a clone of the backup."