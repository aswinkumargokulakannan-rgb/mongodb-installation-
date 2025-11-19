#!/bin/bash

###############################################################################
# Quick Fix: Complete MongoDB Installation
# This script ensures all MongoDB components are properly installed
###############################################################################

set -e

echo "=========================================="
echo "Quick Fix: MongoDB Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo "Step 1: Updating package lists..."
apt-get update

echo ""
echo "Step 2: Installing all MongoDB components..."
apt-get install -y \
    mongodb-org \
    mongodb-org-server \
    mongodb-org-mongos \
    mongodb-org-shell \
    mongodb-mongosh \
    mongodb-org-tools \
    mongodb-database-tools

echo ""
echo "Step 3: Verifying MongoDB installation..."

# Test if mongod is accessible
if [ -f /usr/bin/mongod ]; then
    echo "✓ mongod found at /usr/bin/mongod"
    /usr/bin/mongod --version | head -n 3
else
    echo "⚠ mongod not found at /usr/bin/mongod, searching..."
    find /usr -name mongod -type f 2>/dev/null
fi

echo ""

# Test if mongosh is accessible
if [ -f /usr/bin/mongosh ]; then
    echo "✓ mongosh found at /usr/bin/mongosh"
    /usr/bin/mongosh --version
else
    echo "⚠ mongosh not found at /usr/bin/mongosh, searching..."
    find /usr -name mongosh -type f 2>/dev/null
fi

echo ""
echo "Step 4: Setting up MongoDB directories..."
mkdir -p /var/lib/mongodb
mkdir -p /var/log/mongodb
chown -R mongodb:mongodb /var/lib/mongodb
chown -R mongodb:mongodb /var/log/mongodb
chmod 755 /var/lib/mongodb
chmod 755 /var/log/mongodb

echo ""
echo "Step 5: Reloading systemd..."
systemctl daemon-reload

echo ""
echo "=========================================="
echo "Installation Fixed!"
echo "=========================================="
echo ""
echo "Please verify by running:"
echo "  mongod --version"
echo "  mongosh --version"
echo ""
echo "If they still don't work, close and reopen your terminal, then try again."
echo ""
echo "After verification, continue with:"
echo "  sudo ./03-configure-mongodb.sh"
