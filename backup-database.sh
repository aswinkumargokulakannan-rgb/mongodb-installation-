#!/bin/bash

###############################################################################
# MongoDB Backup Script for vcard Database
# Creates compressed backups with timestamp
###############################################################################

DB_SERVER="192.168.0.14"
DB_PORT="27017"
DB_NAME="vcard"
BACKUP_DIR="/backup/mongodb"
RETENTION_DAYS=7

echo "=========================================="
echo "MongoDB Backup Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Prompt for credentials
read -p "Enter MongoDB username [vcardadmin]: " DB_USER
DB_USER=${DB_USER:-vcardadmin}

read -sp "Enter MongoDB password: " DB_PASSWORD
echo ""
echo ""

if [ -z "$DB_PASSWORD" ]; then
    echo "Password cannot be empty!"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Generate timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/vcard_backup_$TIMESTAMP"

echo "Starting backup..."
echo "Backup location: $BACKUP_PATH"
echo ""

# Run mongodump
CONNECTION_URI="mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}"

if command -v mongodump &> /dev/null; then
    mongodump --uri="$CONNECTION_URI" --out="$BACKUP_PATH"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Backup completed successfully!"

        # Compress the backup
        echo "Compressing backup..."
        tar -czf "${BACKUP_PATH}.tar.gz" -C "$BACKUP_DIR" "$(basename $BACKUP_PATH)"

        if [ $? -eq 0 ]; then
            echo "✓ Backup compressed: ${BACKUP_PATH}.tar.gz"
            # Remove uncompressed backup
            rm -rf "$BACKUP_PATH"

            # Get backup size
            BACKUP_SIZE=$(du -h "${BACKUP_PATH}.tar.gz" | cut -f1)
            echo "Backup size: $BACKUP_SIZE"
        else
            echo "⚠ Compression failed, keeping uncompressed backup"
        fi

        # Cleanup old backups
        echo ""
        echo "Cleaning up backups older than $RETENTION_DAYS days..."
        find "$BACKUP_DIR" -name "vcard_backup_*.tar.gz" -mtime +$RETENTION_DAYS -delete
        find "$BACKUP_DIR" -name "vcard_backup_*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null

        echo ""
        echo "Current backups:"
        ls -lh "$BACKUP_DIR"/vcard_backup_* 2>/dev/null || echo "No backups found"

    else
        echo "✗ Backup failed!"
        exit 1
    fi
else
    echo "✗ mongodump not found!"
    echo "Install it with: sudo apt-get install -y mongodb-database-tools"
    exit 1
fi

echo ""
echo "=========================================="
echo "Backup completed: ${BACKUP_PATH}.tar.gz"
echo "=========================================="
