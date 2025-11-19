#!/bin/bash

###############################################################################
# MongoDB PATH Fix Script
# Fixes issues where MongoDB binaries are not found in PATH
###############################################################################

set -e

echo "=========================================="
echo "MongoDB PATH Fix Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo "Step 1: Locating MongoDB binaries..."

# Common MongoDB binary locations
POSSIBLE_PATHS=(
    "/usr/bin"
    "/usr/local/bin"
    "/opt/mongodb/bin"
    "/var/lib/mongodb"
)

MONGOD_PATH=""
MONGOSH_PATH=""

# Search for mongod
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path/mongod" ]; then
        MONGOD_PATH="$path/mongod"
        echo "Found mongod at: $MONGOD_PATH"
        break
    fi
done

# Search for mongosh
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -f "$path/mongosh" ]; then
        MONGOSH_PATH="$path/mongosh"
        echo "Found mongosh at: $MONGOSH_PATH"
        break
    fi
done

# If not found in common locations, search system-wide
if [ -z "$MONGOD_PATH" ]; then
    echo "Searching for mongod in package installation..."
    MONGOD_PATH=$(dpkg -L mongodb-org-server 2>/dev/null | grep "bin/mongod$" | head -n 1)
    if [ -n "$MONGOD_PATH" ]; then
        echo "Found mongod at: $MONGOD_PATH"
    fi
fi

if [ -z "$MONGOSH_PATH" ]; then
    echo "Searching for mongosh in package installation..."
    MONGOSH_PATH=$(dpkg -L mongodb-mongosh 2>/dev/null | grep "bin/mongosh$" | head -n 1)
    if [ -n "$MONGOSH_PATH" ]; then
        echo "Found mongosh at: $MONGOSH_PATH"
    fi
fi

echo ""
echo "Step 2: Checking package installation status..."
dpkg -l | grep mongodb

echo ""
echo "Step 3: Reinstalling MongoDB packages to ensure proper installation..."

# Remove and reinstall to fix any issues
apt-get update
apt-get install --reinstall -y mongodb-org-server mongodb-org-mongos mongodb-org-shell mongodb-mongosh mongodb-org-tools

echo ""
echo "Step 4: Verifying installation..."

# Check if binaries are now accessible
if command -v mongod &> /dev/null; then
    echo "✓ mongod is now accessible"
    mongod --version
else
    echo "✗ mongod still not found. Checking package contents..."
    dpkg -L mongodb-org-server | grep bin/
fi

echo ""

if command -v mongosh &> /dev/null; then
    echo "✓ mongosh is now accessible"
    mongosh --version
else
    echo "✗ mongosh still not found. Checking package contents..."
    dpkg -L mongodb-mongosh | grep bin/ || echo "mongodb-mongosh package might not be installed"
fi

echo ""
echo "Step 5: Creating symbolic links if needed..."

# Create symlinks if binaries exist but not in PATH
if [ -n "$MONGOD_PATH" ] && [ ! -L "/usr/bin/mongod" ]; then
    ln -sf "$MONGOD_PATH" /usr/bin/mongod
    echo "Created symlink: /usr/bin/mongod -> $MONGOD_PATH"
fi

if [ -n "$MONGOSH_PATH" ] && [ ! -L "/usr/bin/mongosh" ]; then
    ln -sf "$MONGOSH_PATH" /usr/bin/mongosh
    echo "Created symlink: /usr/bin/mongosh -> $MONGOSH_PATH"
fi

echo ""
echo "Step 6: Updating PATH and reloading environment..."
export PATH="/usr/bin:$PATH"

# Check one more time
echo ""
echo "Final verification:"
echo "===================="

if command -v mongod &> /dev/null; then
    echo "✓ mongod: $(which mongod)"
    mongod --version | head -n 1
else
    echo "✗ mongod: NOT FOUND"
fi

if command -v mongosh &> /dev/null; then
    echo "✓ mongosh: $(which mongosh)"
    mongosh --version
else
    echo "✗ mongosh: NOT FOUND"
    echo ""
    echo "Installing mongosh separately..."
    apt-get install -y mongodb-mongosh || {
        echo "Using alternative mongosh installation method..."
        wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list
        apt-get update
        apt-get install -y mongodb-mongosh
    }
fi

echo ""
echo "=========================================="
echo "PATH Fix Completed!"
echo "=========================================="
echo ""
echo "If mongod/mongosh are still not found, you may need to:"
echo "1. Log out and log back in, or"
echo "2. Run: source ~/.bashrc"
echo "3. Or start a new terminal session"
