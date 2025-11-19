#!/bin/bash

###############################################################################
# Direct Binary Fix - MongoDB
# Finds MongoDB binaries and creates symlinks directly
###############################################################################

echo "=========================================="
echo "Direct MongoDB Binary Fix"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo "Searching for MongoDB binaries in the system..."
echo ""

# Search for mongod
echo "Looking for mongod..."
MONGOD_PATHS=$(dpkg -L mongodb-org-server 2>/dev/null | grep -E "bin/mongod$|sbin/mongod$")

if [ -z "$MONGOD_PATHS" ]; then
    echo "Searching filesystem..."
    MONGOD_PATHS=$(find /usr /opt -name mongod -type f 2>/dev/null)
fi

if [ -n "$MONGOD_PATHS" ]; then
    # Get the first result
    MONGOD_PATH=$(echo "$MONGOD_PATHS" | head -n 1)
    echo "✓ Found mongod at: $MONGOD_PATH"

    # Create symlink
    if [ ! -f /usr/bin/mongod ] || [ -L /usr/bin/mongod ]; then
        ln -sf "$MONGOD_PATH" /usr/bin/mongod
        echo "  Created symlink: /usr/bin/mongod -> $MONGOD_PATH"
    fi

    # Make executable
    chmod +x "$MONGOD_PATH"
    chmod +x /usr/bin/mongod

    # Test
    /usr/bin/mongod --version 2>/dev/null && echo "  ✓ mongod is working!" || echo "  ✗ mongod test failed"
else
    echo "✗ mongod not found in package files or filesystem"
fi

echo ""

# Search for mongosh
echo "Looking for mongosh..."
MONGOSH_PATHS=$(dpkg -L mongodb-mongosh 2>/dev/null | grep -E "bin/mongosh$")

if [ -z "$MONGOSH_PATHS" ]; then
    echo "Searching filesystem..."
    MONGOSH_PATHS=$(find /usr /opt -name mongosh -type f 2>/dev/null)
fi

if [ -n "$MONGOSH_PATHS" ]; then
    # Get the first result
    MONGOSH_PATH=$(echo "$MONGOSH_PATHS" | head -n 1)
    echo "✓ Found mongosh at: $MONGOSH_PATH"

    # Create symlink
    if [ ! -f /usr/bin/mongosh ] || [ -L /usr/bin/mongosh ]; then
        ln -sf "$MONGOSH_PATH" /usr/bin/mongosh
        echo "  Created symlink: /usr/bin/mongosh -> $MONGOSH_PATH"
    fi

    # Make executable
    chmod +x "$MONGOSH_PATH"
    chmod +x /usr/bin/mongosh

    # Test
    /usr/bin/mongosh --version 2>/dev/null && echo "  ✓ mongosh is working!" || echo "  ✗ mongosh test failed"
else
    echo "✗ mongosh not found in package files or filesystem"
fi

echo ""
echo "Step 3: Listing all MongoDB package files..."
echo "mongodb-org-server files:"
dpkg -L mongodb-org-server 2>/dev/null | grep bin/ | head -n 20

echo ""
echo "mongodb-mongosh files:"
dpkg -L mongodb-mongosh 2>/dev/null | grep bin/ | head -n 20

echo ""
echo "Step 4: Checking /usr/bin for MongoDB binaries..."
ls -la /usr/bin/ | grep -E "mongo|mongo"

echo ""
echo "Step 5: Refreshing command hash..."
hash -r

echo ""
echo "=========================================="
echo "Fix Applied!"
echo "=========================================="
echo ""
echo "Testing commands directly:"
echo "-------------------------"

if [ -f /usr/bin/mongod ]; then
    echo "mongod:"
    /usr/bin/mongod --version 2>&1 | head -n 3 || echo "Failed to run mongod"
else
    echo "mongod: NOT FOUND at /usr/bin/mongod"
fi

echo ""

if [ -f /usr/bin/mongosh ]; then
    echo "mongosh:"
    /usr/bin/mongosh --version 2>&1 || echo "Failed to run mongosh"
else
    echo "mongosh: NOT FOUND at /usr/bin/mongosh"
fi

echo ""
echo "If binaries are working above, try these commands:"
echo "  hash -r"
echo "  mongod --version"
echo "  mongosh --version"
echo ""
echo "If still not working, you may need to open a new terminal session."
