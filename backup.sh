#!/bin/bash
set -e

# --- CONFIGURATION ---
CONTAINER_FILTER="name=drupal_drupal_cms"
BACKUP_DIR_BASE="./backups"
BACKUP_FILENAME="drupal-backup.tar.gz"
BACKUP_DEST_IN_CONTAINER="/tmp/$BACKUP_FILENAME"

# --- SCRIPT START ---
BACKUP_DIR="$BACKUP_DIR_BASE/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"

# --- HELPER FUNCTIONS ---
# Finds the container ID and exits if not found.
get_container_id() {
  local id
  id=$(docker ps -q --filter "$CONTAINER_FILTER" | head -n 1)
  if [ -z "$id" ]; then
    echo "Error: Could not find a running container with filter '$CONTAINER_FILTER'." >&2
    exit 1
  fi
  echo "$id"
}

# Executes a command inside the Drupal container.
run_in_container() {
  docker exec "$(get_container_id)" "$@"
}

# Function to always disable maintenance mode.
cleanup() {
  echo "Running cleanup: Disabling maintenance mode..."
  run_in_container vendor/bin/drush sset system.maintenance_mode 0 -y || echo "Failed to disable maintenance mode, but continuing."
}

# --- TRAP ---
# Set a trap to run the cleanup function on any script error.
trap 'echo "An error occurred." >&2; cleanup; exit 1' ERR

# --- MAIN LOGIC ---
echo "Starting backup process..."

echo "Enabling maintenance mode..."
run_in_container vendor/bin/drush sset system.maintenance_mode 1 -y

echo "Creating archive dump inside the container..."
run_in_container vendor/bin/drush archive:dump --db --files --destination="$BACKUP_DEST_IN_CONTAINER" -y

echo "Copying archive from container to host: $BACKUP_DIR/$BACKUP_FILENAME"
docker cp "$(get_container_id)":"$BACKUP_DEST_IN_CONTAINER" "$BACKUP_DIR/"

echo "Cleaning up temporary archive file in container..."
run_in_container rm "$BACKUP_DEST_IN_CONTAINER"

# --- FINAL CLEANUP ---
# Disable maintenance mode now that the script has completed successfully.
cleanup

# Remove the error trap.
trap - ERR

echo "✅ Backup complete! Archive is located in: $BACKUP_DIR"