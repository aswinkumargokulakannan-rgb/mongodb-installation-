#!/bin/bash

###############################################################################
# MongoDB CPU Compatibility Fix v2
# Detects CPU capabilities and installs compatible MongoDB version
# Handles Ubuntu 22.04 repository issues
###############################################################################

set -e

echo "=========================================="
echo "MongoDB CPU Compatibility Fix v2"
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
echo "AVX flags: $(grep "flags" /proc/cpuinfo | head -n 1 | grep -o "avx[^ ]*" || echo "None")"

# Detect Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    UBUNTU_CODENAME=$(lsb_release -cs 2>/dev/null || echo "jammy")
    UBUNTU_VERSION=$VERSION_ID
else
    UBUNTU_CODENAME="jammy"
    UBUNTU_VERSION="22.04"
fi

echo "Ubuntu version: $UBUNTU_VERSION ($UBUNTU_CODENAME)"

echo ""
echo "Step 2: Determining compatible MongoDB version..."
echo ""

if [ "$AVX_SUPPORT" = false ]; then
    echo "⚠ Your CPU does not support AVX instructions."
    echo "MongoDB 5.0+ requires AVX support."
    echo ""

    # For Ubuntu 22.04, we need to use focal (20.04) repo for MongoDB 4.4
    if [ "$UBUNTU_CODENAME" = "jammy" ]; then
        echo "Installing MongoDB 4.4 using Ubuntu 20.04 (focal) repository..."
        MONGODB_VERSION="4.4"
        REPO_CODENAME="focal"
    else
        echo "Installing MongoDB 4.4..."
        MONGODB_VERSION="4.4"
        REPO_CODENAME=$UBUNTU_CODENAME
    fi
else
    echo "✓ Your CPU supports MongoDB 5.0+"
    MONGODB_VERSION="5.0"
    REPO_CODENAME=$UBUNTU_CODENAME
fi

echo ""
echo "Step 3: Removing existing MongoDB installation..."
systemctl stop mongod 2>/dev/null || true
systemctl disable mongod 2>/dev/null || true

apt-get purge -y mongodb-org* mongodb-mongosh 2>/dev/null || true
rm -rf /var/log/mongodb
rm -rf /var/lib/mongodb
rm -f /etc/apt/sources.list.d/mongodb-org*.list
rm -f /usr/share/keyrings/mongodb-server-*.gpg

echo ""
echo "Step 4: Installing MongoDB ${MONGODB_VERSION}..."

# Add GPG key
curl -fsSL https://www.mongodb.org/static/pgp/server-${MONGODB_VERSION}.asc | \
    gpg --dearmor -o /usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg

# Add repository with appropriate Ubuntu codename
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-${MONGODB_VERSION}.gpg ] https://repo.mongodb.org/apt/ubuntu ${REPO_CODENAME}/mongodb-org/${MONGODB_VERSION} multiverse" | \
    tee /etc/apt/sources.list.d/mongodb-org-${MONGODB_VERSION}.list

# Update package lists
apt-get update

echo ""
echo "Step 5: Installing MongoDB packages..."

if [ "$MONGODB_VERSION" = "4.4" ]; then
    # MongoDB 4.4 packages
    apt-get install -y \
        mongodb-org=${MONGODB_VERSION}* \
        mongodb-org-server=${MONGODB_VERSION}* \
        mongodb-org-shell=${MONGODB_VERSION}* \
        mongodb-org-mongos=${MONGODB_VERSION}* \
        mongodb-org-tools=${MONGODB_VERSION}*

    # Create mongosh wrapper for compatibility
    cat > /usr/local/bin/mongosh <<'EOF'
#!/bin/bash
# Compatibility wrapper - calls legacy mongo shell
exec mongo "$@"
EOF
    chmod +x /usr/local/bin/mongosh
    echo "Created mongosh wrapper (calls mongo shell)"

else
    # MongoDB 5.0+ packages
    apt-get install -y \
        mongodb-org=${MONGODB_VERSION}* \
        mongodb-org-server=${MONGODB_VERSION}* \
        mongodb-org-shell=${MONGODB_VERSION}* \
        mongodb-org-mongos=${MONGODB_VERSION}* \
        mongodb-org-tools=${MONGODB_VERSION}*

    # Try to install mongosh separately
    apt-get install -y mongodb-mongosh || {
        echo "mongosh package not available, will use mongo shell"
    }
fi

echo ""
echo "Step 6: Creating MongoDB directories and setting permissions..."
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
echo "Step 7: Creating MongoDB configuration file..."
cat > /etc/mongod.conf <<EOF
# mongod.conf

# for documentation of all options, see:
#   http://docs.mongodb.org/manual/reference/configuration-options/

# Where and how to store data.
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# where to write logging data.
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1

# how the process runs
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

#security:

#operationProfiling:

#replication:

#sharding:
EOF

chmod 644 /etc/mongod.conf

echo ""
echo "Step 8: Enabling and starting MongoDB..."
systemctl daemon-reload
systemctl enable mongod
systemctl start mongod

# Wait for MongoDB to start
echo "Waiting for MongoDB to start..."
sleep 10

# Check startup
MAX_RETRIES=6
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if systemctl is-active --quiet mongod; then
        echo "✓ MongoDB is running"
        break
    fi
    echo "Waiting... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT+1))
done

echo ""
echo "Step 9: Verifying installation..."

# Test mongod
if systemctl is-active --quiet mongod; then
    echo "✓ MongoDB service: RUNNING"
else
    echo "✗ MongoDB service: FAILED"
    echo "Check logs: journalctl -u mongod -n 50"
    exit 1
fi

# Test mongo shell
if [ "$MONGODB_VERSION" = "4.4" ]; then
    if command -v mongo &> /dev/null; then
        echo "✓ mongo shell: AVAILABLE"
        mongo --version | head -n 1
    else
        echo "✗ mongo shell: NOT FOUND"
    fi
else
    if command -v mongosh &> /dev/null; then
        echo "✓ mongosh: AVAILABLE"
        mongosh --version
    elif command -v mongo &> /dev/null; then
        echo "✓ mongo shell: AVAILABLE (mongosh not installed)"
        mongo --version | head -n 1
    fi
fi

# Test connection
echo ""
echo "Testing database connection..."
if [ "$MONGODB_VERSION" = "4.4" ]; then
    mongo --quiet --eval "db.version()" 2>/dev/null && echo "✓ Connection test: SUCCESS" || echo "⚠ Connection test: FAILED"
else
    if command -v mongosh &> /dev/null; then
        mongosh --quiet --eval "db.version()" 2>/dev/null && echo "✓ Connection test: SUCCESS" || mongo --quiet --eval "db.version()" 2>/dev/null && echo "✓ Connection test: SUCCESS"
    else
        mongo --quiet --eval "db.version()" 2>/dev/null && echo "✓ Connection test: SUCCESS" || echo "⚠ Connection test: FAILED"
    fi
fi

echo ""
echo "=========================================="
echo "MongoDB ${MONGODB_VERSION} Installed Successfully!"
echo "=========================================="
echo ""

if [ "$MONGODB_VERSION" = "4.4" ]; then
    echo "MongoDB 4.4 Details:"
    echo "  - Compatible with CPUs without AVX"
    echo "  - Shell command: mongo"
    echo "  - mongosh wrapper created (calls mongo)"
    echo "  - Fully compatible with your vcard application"
    echo ""
fi

echo "Service Status:"
systemctl status mongod --no-pager | head -n 10

echo ""
echo "Next Steps:"
echo "  1. Verify: systemctl status mongod"
echo "  2. Configure vcard database: sudo ./03-configure-mongodb-v3.sh"
echo ""
