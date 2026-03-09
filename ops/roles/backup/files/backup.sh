#!/bin/bash
#
# Backup script using restic
# Usage: backup.sh <folders> <restic repository>
# 
#################################################
#                                               #
#           DO NOT MODIFY THIS FILE!            #
#            Modified using Ansible.            #
#                                               #
#################################################

# Exit on error
set -e

# Ensure correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <folder> <restic repository>"
    exit 1
fi

# Extract arguments
FOLDER="$1"
export RESTIC_REPOSITORY="$2"
export RESTIC_PASSWORD_FILE="/etc/restic/encryption_key"

# Initialize repository if not already initialized
if ! restic snapshots &>/dev/null; then
    echo "Initializing restic repository..."
    restic init
fi

# Run backup
echo "Starting backup..."
restic backup "${FOLDER}"

# Prune old backups and optimize storage
restic forget --keep-last 5 --keep-daily 3 --keep-weekly 3 --keep-monthly 6 --prune

# Verify backup integrity
restic check

echo "Backup completed successfully."
