#!/bin/bash

###############################################################################
# MongoDB Restore Script for vcard Database
# Restores database from backup
###############################################################################

DB_SERVER="192.168.0.14"
DB_PORT="27017"
DB_NAME="vcard"
BACKUP_DIR="/backup/mongodb"

echo "=========================================="
echo "MongoDB Restore Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# List available backups
echo "Available backups:"
echo ""
ls -lh "$BACKUP_DIR"/vcard_backup_*.tar.gz 2>/dev/null

if [ $? -ne 0 ]; then
    echo "No backups found in $BACKUP_DIR"
    exit 1
fi

echo ""
read -p "Enter the full path to the backup file to restore: " BACKUP_FILE

if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE"
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

# Warning
echo ""
echo "⚠ WARNING: This will REPLACE all data in the '$DB_NAME' database!"
read -p "Are you sure you want to continue? (yes/no): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Restore cancelled."
    exit 0
fi

# Extract backup if it's compressed
TEMP_DIR="/tmp/mongodb_restore_$$"
mkdir -p "$TEMP_DIR"

echo ""
echo "Extracting backup..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

if [ $? -ne 0 ]; then
    echo "✗ Failed to extract backup"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Find the extracted directory
EXTRACTED_DIR=$(find "$TEMP_DIR" -type d -name "vcard_backup_*" | head -n 1)

if [ -z "$EXTRACTED_DIR" ]; then
    echo "✗ Could not find extracted backup directory"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Run mongorestore
CONNECTION_URI="mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}"

echo "Starting restore..."
echo ""

if command -v mongorestore &> /dev/null; then
    mongorestore --uri="$CONNECTION_URI" --drop "$EXTRACTED_DIR/$DB_NAME"

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ Restore completed successfully!"
    else
        echo "✗ Restore failed!"
        rm -rf "$TEMP_DIR"
        exit 1
    fi
else
    echo "✗ mongorestore not found!"
    echo "Install it with: sudo apt-get install -y mongodb-database-tools"
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Cleanup
rm -rf "$TEMP_DIR"

echo ""
echo "=========================================="
echo "Restore completed from: $BACKUP_FILE"
echo "=========================================="
