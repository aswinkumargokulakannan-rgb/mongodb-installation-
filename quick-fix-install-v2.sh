#!/bin/bash

###############################################################################
# Quick Fix v2: Complete MongoDB Installation (Handles Held Packages)
# This script ensures all MongoDB components are properly installed
###############################################################################

set -e

echo "=========================================="
echo "Quick Fix v2: MongoDB Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo "Step 1: Unholding any held MongoDB packages..."
apt-mark unhold mongodb-org-shell mongodb-org-mongos mongodb-org-server mongodb-org-tools 2>/dev/null || true

echo ""
echo "Step 2: Updating package lists..."
apt-get update

echo ""
echo "Step 3: Installing all MongoDB components with --allow-change-held-packages..."
apt-get install -y --allow-change-held-packages \
    mongodb-org \
    mongodb-org-server \
    mongodb-org-mongos \
    mongodb-org-shell \
    mongodb-mongosh \
    mongodb-org-tools \
    mongodb-database-tools

echo ""
echo "Step 4: Verifying MongoDB installation..."

# Give the system a moment
sleep 2

# Test if mongod is accessible
echo "Checking for mongod..."
if command -v mongod &> /dev/null; then
    echo "✓ mongod found in PATH"
    mongod --version | head -n 3
elif [ -f /usr/bin/mongod ]; then
    echo "✓ mongod found at /usr/bin/mongod"
    /usr/bin/mongod --version | head -n 3
else
    echo "⚠ mongod not found in standard locations, searching..."
    MONGOD_PATH=$(find /usr -name mongod -type f 2>/dev/null | head -n 1)
    if [ -n "$MONGOD_PATH" ]; then
        echo "Found mongod at: $MONGOD_PATH"
        # Create symlink
        ln -sf "$MONGOD_PATH" /usr/bin/mongod
        echo "Created symlink: /usr/bin/mongod -> $MONGOD_PATH"
    else
        echo "✗ mongod not found anywhere!"
    fi
fi

echo ""

# Test if mongosh is accessible
echo "Checking for mongosh..."
if command -v mongosh &> /dev/null; then
    echo "✓ mongosh found in PATH"
    mongosh --version
elif [ -f /usr/bin/mongosh ]; then
    echo "✓ mongosh found at /usr/bin/mongosh"
    /usr/bin/mongosh --version
else
    echo "⚠ mongosh not found in standard locations, searching..."
    MONGOSH_PATH=$(find /usr -name mongosh -type f 2>/dev/null | head -n 1)
    if [ -n "$MONGOSH_PATH" ]; then
        echo "Found mongosh at: $MONGOSH_PATH"
        # Create symlink
        ln -sf "$MONGOSH_PATH" /usr/bin/mongosh
        echo "Created symlink: /usr/bin/mongosh -> $MONGOSH_PATH"
    else
        echo "✗ mongosh not found anywhere!"
    fi
fi

echo ""
echo "Step 5: Setting up MongoDB directories..."
mkdir -p /var/lib/mongodb
mkdir -p /var/log/mongodb

# Ensure mongodb user exists
if ! id mongodb &> /dev/null; then
    echo "Creating mongodb user..."
    useradd -r -s /bin/false mongodb
fi

chown -R mongodb:mongodb /var/lib/mongodb
chown -R mongodb:mongodb /var/log/mongodb
chmod 755 /var/lib/mongodb
chmod 755 /var/log/mongodb

echo ""
echo "Step 6: Reloading systemd and updating environment..."
systemctl daemon-reload
hash -r

echo ""
echo "Step 7: Final verification..."
echo "===================="

# Force PATH refresh
export PATH="/usr/bin:/usr/local/bin:$PATH"

if /usr/bin/mongod --version &> /dev/null; then
    echo "✓ mongod: /usr/bin/mongod"
    /usr/bin/mongod --version | head -n 1
else
    echo "✗ mongod: VERIFICATION FAILED"
fi

if /usr/bin/mongosh --version &> /dev/null; then
    echo "✓ mongosh: /usr/bin/mongosh"
    /usr/bin/mongosh --version
else
    echo "✗ mongosh: VERIFICATION FAILED"
fi

echo ""
echo "=========================================="
echo "Installation Fixed!"
echo "=========================================="
echo ""
echo "IMPORTANT: Close this terminal and open a new one, then verify:"
echo "  mongod --version"
echo "  mongosh --version"
echo ""
echo "Or refresh your current session:"
echo "  hash -r"
echo "  mongod --version"
echo ""
echo "After verification, continue with:"
echo "  sudo ./03-configure-mongodb-v2.sh"
echo ""
