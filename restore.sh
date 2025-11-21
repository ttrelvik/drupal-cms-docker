#!/bin/bash
set -e

# --- CONFIGURATION ---
CONTAINER_FILTER="^drupal_dev_drupal_cms"
BACKUP_FILENAME="drupal-backup.tar.gz"
RESTORE_DEST_IN_CONTAINER="/tmp/$BACKUP_FILENAME"
EXTRACT_DIR="/tmp/restore_temp"

# --- SCRIPT START ---
if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <path_to_backup_directory>"
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
  docker exec -i "$(get_container_id)" "$@"
}

# --- MAIN LOGIC ---
echo "Starting restore process for dev environment..."

echo "Step 1: Preparing settings.php..."
run_in_container cp /app/web/sites/default/default.settings.php /app/web/sites/default/settings.php
run_in_container chmod 664 /app/web/sites/default/settings.php
HASH_SALT=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 55)
run_in_container sh -c 'cat >> /app/web/sites/default/settings.php' <<EOF

\$settings['hash_salt'] = '$HASH_SALT';
EOF

echo "Step 2: Copying backup archive into the container..."
docker cp "$BACKUP_PATH" "$(get_container_id):$RESTORE_DEST_IN_CONTAINER"

echo "Step 3: Extracting the archive inside the container..."
run_in_container mkdir -p "$EXTRACT_DIR"
run_in_container tar -xzf "$RESTORE_DEST_IN_CONTAINER" -C "$EXTRACT_DIR"

echo "Step 4: Restoring the database..."
run_in_container drush sql:drop -y
run_in_container sh -c "drush sql:cli < $EXTRACT_DIR/database/database.sql 2>/dev/null"

echo "Step 5: Restoring the files..."
run_in_container rsync -a --delete "$EXTRACT_DIR/files/" /app/web/sites/default/files/

echo "Step 6: Cleaning up temporary files in container..."
run_in_container rm "$RESTORE_DEST_IN_CONTAINER"
run_in_container rm -rf "$EXTRACT_DIR"

echo "Step 7: Finalizing the site..."
echo "Setting file permissions..."
run_in_container chown -R www-data:www-data /app/web/sites/default/files
echo "Running database updates..."
run_in_container drush updb -y
echo "Disabling maintenance mode..."
run_in_container drush sset system.maintenance_mode 0 -y
echo "Clearing caches..."
run_in_container drush cr

echo "✅ Restore complete!"