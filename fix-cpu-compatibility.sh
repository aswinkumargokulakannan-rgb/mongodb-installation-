#!/bin/bash

###############################################################################
# MongoDB CPU Compatibility Fix
# Detects CPU capabilities and installs compatible MongoDB version
###############################################################################

set -e

echo "=========================================="
echo "MongoDB CPU Compatibility Fix"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo "Step 1: Checking CPU capabilities..."
echo ""

# Check for AVX support
if grep -q avx /proc/cpuinfo; then
    echo "✓ CPU supports AVX instructions"
    AVX_SUPPORT=true
else
    echo "✗ CPU does NOT support AVX instructions"
    AVX_SUPPORT=false
fi

# Check CPU info
echo ""
echo "CPU Information:"
echo "----------------"
grep "model name" /proc/cpuinfo | head -n 1
grep "flags" /proc/cpuinfo | head -n 1 | cut -d: -f2 | grep -o "avx[^ ]*" || echo "No AVX flags found"

echo ""
echo "Step 2: Determining compatible MongoDB version..."
echo ""

if [ "$AVX_SUPPORT" = false ]; then
    echo "⚠ Your CPU does not support AVX instructions."
    echo "MongoDB 7.0+ requires AVX support."
    echo "Installing MongoDB 4.4 (last version without AVX requirement)..."
    echo ""

    MONGODB_VERSION="4.4"
    MONGODB_REPO="https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/4.4 multiverse"
else
    echo "✓ Your CPU supports MongoDB 7.0"
    MONGODB_VERSION="7.0"
    MONGODB_REPO="https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse"
fi

echo ""
echo "Step 3: Removing existing MongoDB installation..."
systemctl stop mongod 2>/dev/null || true

apt-get purge -y mongodb-org* 2>/dev/null || true
rm -rf /var/log/mongodb
rm -rf /var/lib/mongodb
rm -f /etc/apt/sources.list.d/mongodb-org*.list

echo ""
echo "Step 4: Installing MongoDB ${MONGODB_VERSION}..."

# Add GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg

# Add repository
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] ${MONGODB_REPO}" | \
    tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list

# Update and install
apt-get update
apt-get install -y mongodb-org mongodb-org-server mongodb-org-shell mongodb-org-mongos mongodb-org-tools

echo ""
echo "Step 5: Installing mongosh separately (if needed)..."
if [ "$MONGODB_VERSION" = "4.4" ]; then
    # For MongoDB 4.4, we need to install mongosh separately
    # But use the legacy mongo shell which is included
    echo "MongoDB 4.4 uses 'mongo' shell (not mongosh)"
    echo "Creating mongosh alias for compatibility..."

    cat > /usr/local/bin/mongosh <<'EOF'
#!/bin/bash
# Compatibility wrapper - calls legacy mongo shell
exec mongo "$@"
EOF
    chmod +x /usr/local/bin/mongosh
fi

echo ""
echo "Step 6: Creating MongoDB directories..."
mkdir -p /var/lib/mongodb
mkdir -p /var/log/mongodb

# Ensure mongodb user exists
if ! id mongodb &> /dev/null; then
    useradd -r -s /bin/false mongodb
fi

chown -R mongodb:mongodb /var/lib/mongodb
chown -R mongodb:mongodb /var/log/mongodb
chmod 755 /var/lib/mongodb
chmod 755 /var/log/mongodb

echo ""
echo "Step 7: Enabling and starting MongoDB..."
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to start
sleep 5

echo ""
echo "Step 8: Verifying installation..."
if [ "$MONGODB_VERSION" = "4.4" ]; then
    mongod --version
    echo ""
    echo "MongoDB shell command: mongo (or mongosh as alias)"
else
    mongod --version
    if command -v mongosh &> /dev/null; then
        mongosh --version
    fi
fi

echo ""
if systemctl is-active --quiet mongod; then
    echo "✓ MongoDB is running successfully!"
else
    echo "✗ MongoDB failed to start"
    echo "Check logs: journalctl -u mongod -n 50"
    exit 1
fi

echo ""
echo "=========================================="
echo "MongoDB ${MONGODB_VERSION} Installed Successfully!"
echo "=========================================="
echo ""

if [ "$MONGODB_VERSION" = "4.4" ]; then
    echo "⚠ Important Notes for MongoDB 4.4:"
    echo "  - Use 'mongo' command for shell (mongosh is aliased to mongo)"
    echo "  - MongoDB 4.4 is the last version without AVX requirement"
    echo "  - Full feature compatibility with your application"
    echo ""
fi

echo "Next steps:"
echo "  1. Verify: systemctl status mongod"
echo "  2. Test shell: mongo (or mongosh)"
echo "  3. Configure: sudo ./03-configure-mongodb-v2.sh"
echo ""
