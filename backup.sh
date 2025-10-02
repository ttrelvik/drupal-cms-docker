#!/bin/bash
set -e

# --- CONFIGURATION ---
# Directory on the host machine where backups will be stored.
BACKUP_DIR_BASE="./backups"
# The name filter to find the running Drupal container in Swarm.
# This is typically <stack_name>_<service_name>.
CONTAINER_FILTER="name=drupal_drupal_cms"

# --- SCRIPT START ---
# Create a timestamped directory for the current backup.
BACKUP_DIR="$BACKUP_DIR_BASE/$(date +%Y-%m-%d_%H-%M-%S)"
mkdir -p "$BACKUP_DIR"

# Function to execute a command inside the Drupal container.
# This avoids repeating the long 'docker exec' command.
run_in_container() {
  local container_id
  container_id=$(docker ps -q --filter "$CONTAINER_FILTER" | head -n 1)
  if [ -z "$container_id" ]; then
    echo "Error: Could not find a running container with filter '$CONTAINER_FILTER'."
    exit 1
  fi
  docker exec "$container_id" "$@"
}

echo "Starting backup process..."

# --- MAINTENANCE MODE: ON ---
echo "Enabling maintenance mode..."
run_in_container vendor/bin/drush sset system.maintenance_mode 1 -y

# TRAP to ensure maintenance mode is turned off if the script fails.
trap 'echo "An error occurred. Disabling maintenance mode..."; run_in_container vendor/bin/drush sset system.maintenance_mode 0 -y; exit 1' ERR

# --- CORE BACKUP LOGIC ---
BACKUP_FILENAME="drupal-backup.tar.gz"
BACKUP_DEST_IN_CONTAINER="/tmp/$BACKUP_FILENAME"

# 1. Create the archive inside the container using drush.
# This command archives the database and public files, excluding the codebase.
echo "Creating archive dump inside the container..."
run_in_container vendor/bin/drush archive:dump --db --files --destination="$BACKUP_DEST_IN_CONTAINER" -y

# 2. Copy the backup from the container to the host.
echo "Copying archive from container to host: $BACKUP_DIR/$BACKUP_FILENAME"
docker cp "$(docker ps -q --filter "$CONTAINER_FILTER" | head -n 1)":"$BACKUP_DEST_IN_CONTAINER" "$BACKUP_DIR/"

# 3. Clean up the temporary archive file inside the container.
echo "Cleaning up temporary archive file in container..."
run_in_container rm "$BACKUP_DEST_IN_CONTAINER"

# --- MAINTENANCE MODE: OFF ---
echo "Disabling maintenance mode..."
run_in_container vendor/bin/drush sset system.maintenance_mode 0 -y

# --- CLEANUP ---
# Remove the trap now that the script has completed successfully.
trap - ERR

echo "✅ Backup complete! Archive is located in: $BACKUP_DIR"