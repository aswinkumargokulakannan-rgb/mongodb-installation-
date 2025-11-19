#!/bin/bash

###############################################################################
# MongoDB Configuration and Security Setup Script (v4 - Fixed shell detection)
# Configures MongoDB for remote access from Application Server (192.168.0.10)
# Creates 'vcard' database with authentication
# Properly detects MongoDB 4.4 vs 5.0+ and uses correct shell syntax
###############################################################################

set -e

echo "=========================================="
echo "MongoDB Configuration Script v4"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

DB_SERVER_IP="192.168.0.14"
APP_SERVER_IP="192.168.0.10"
DB_NAME="vcard"

# Detect MongoDB version first to determine which shell to use
MONGO_VERSION=""
if mongod --version 2>/dev/null | grep -q "v4.4"; then
    MONGO_VERSION="4.4"
    MONGO_SHELL="mongo"
    echo "Detected: MongoDB 4.4 (using mongo shell)"
elif mongod --version 2>/dev/null | grep -q "v5.0"; then
    MONGO_VERSION="5.0"
    MONGO_SHELL="mongosh"
    echo "Detected: MongoDB 5.0 (using mongosh)"
elif mongod --version 2>/dev/null | grep -q "v7.0"; then
    MONGO_VERSION="7.0"
    MONGO_SHELL="mongosh"
    echo "Detected: MongoDB 7.0 (using mongosh)"
else
    # Fallback: try to determine from shell availability and actual version check
    if command -v mongo &> /dev/null; then
        MONGO_SHELL="mongo"
        MONGO_VERSION="4.4"
        echo "Detected: MongoDB 4.4 or earlier (using mongo shell)"
    elif command -v mongosh &> /dev/null; then
        MONGO_SHELL="mongosh"
        MONGO_VERSION="5.0+"
        echo "Detected: MongoDB 5.0+ (using mongosh)"
    else
        echo "ERROR: No MongoDB shell found!"
        exit 1
    fi
fi

echo "Using MongoDB shell: $MONGO_SHELL"
echo ""

# Prompt for database credentials
echo "Setting up MongoDB authentication for the 'vcard' database"
echo ""
read -p "Enter username for vcard database [default: vcardadmin]: " DB_USER
DB_USER=${DB_USER:-vcardadmin}

while true; do
    read -sp "Enter password for $DB_USER: " DB_PASSWORD
    echo ""
    read -sp "Confirm password: " DB_PASSWORD_CONFIRM
    echo ""
    if [ "$DB_PASSWORD" = "$DB_PASSWORD_CONFIRM" ]; then
        break
    else
        echo "Passwords do not match. Please try again."
    fi
done

if [ -z "$DB_PASSWORD" ]; then
    echo "Password cannot be empty!"
    exit 1
fi

echo ""
echo "Step 1: Backing up existing MongoDB configuration..."
if [ -f /etc/mongod.conf ]; then
    cp /etc/mongod.conf /etc/mongod.conf.backup.$(date +%Y%m%d_%H%M%S)
fi

echo "Step 2: Creating MongoDB configuration file (without auth for user creation)..."
cat > /etc/mongod.conf <<EOF
# mongod.conf - MongoDB Configuration File

# Where to store data
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# Where to write logging data
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1,${DB_SERVER_IP}

# Process management
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

# Security - disabled temporarily to create users
#security:
#  authorization: enabled
EOF

echo "Step 3: Setting proper permissions on configuration file..."
chmod 644 /etc/mongod.conf
chown root:root /etc/mongod.conf

echo "Step 4: Restarting MongoDB to apply configuration..."
systemctl restart mongod

# Wait for MongoDB to start
echo "Waiting for MongoDB to start..."
sleep 10

# Check if MongoDB is running
MAX_RETRIES=12
RETRY_COUNT=0
while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    if systemctl is-active --quiet mongod; then
        echo "✓ MongoDB is running"
        break
    fi
    echo "Waiting for MongoDB... ($((RETRY_COUNT+1))/$MAX_RETRIES)"
    sleep 5
    RETRY_COUNT=$((RETRY_COUNT+1))
done

if ! systemctl is-active --quiet mongod; then
    echo "ERROR: MongoDB failed to start. Check logs with: journalctl -u mongod -n 50"
    exit 1
fi

# Additional wait for MongoDB to be ready
sleep 5

echo "Step 5: Creating MongoDB admin user..."

# Use appropriate syntax based on MongoDB version
if [ "$MONGO_SHELL" = "mongo" ]; then
    # MongoDB 4.4 and earlier - use legacy mongo shell syntax
    $MONGO_SHELL --quiet <<EOF
use admin
db.createUser({
  user: "admin",
  pwd: "${DB_PASSWORD}",
  roles: [
    { role: "userAdminAnyDatabase", db: "admin" },
    { role: "readWriteAnyDatabase", db: "admin" },
    { role: "dbAdminAnyDatabase", db: "admin" },
    { role: "clusterAdmin", db: "admin" }
  ]
})
print("Admin user created successfully")
EOF

else
    # MongoDB 5.0+ - use mongosh syntax
    $MONGO_SHELL --quiet --eval "
use admin
try {
  db.createUser({
    user: 'admin',
    pwd: '${DB_PASSWORD}',
    roles: [
      { role: 'userAdminAnyDatabase', db: 'admin' },
      { role: 'readWriteAnyDatabase', db: 'admin' },
      { role: 'dbAdminAnyDatabase', db: 'admin' },
      { role: 'clusterAdmin', db: 'admin' }
    ]
  })
  print('Admin user created successfully')
} catch(e) {
  if (e.code === 51003) {
    print('Admin user already exists, skipping...')
  } else {
    throw e
  }
}
"
fi

echo "Step 6: Creating 'vcard' database and user..."

if [ "$MONGO_SHELL" = "mongo" ]; then
    # MongoDB 4.4 and earlier
    $MONGO_SHELL --quiet <<EOF
use ${DB_NAME}
db.createUser({
  user: "${DB_USER}",
  pwd: "${DB_PASSWORD}",
  roles: [
    { role: "readWrite", db: "${DB_NAME}" },
    { role: "dbAdmin", db: "${DB_NAME}" }
  ]
})
print("Database user created successfully")

db.createCollection("test_collection")
db.test_collection.insertOne({test: "Database initialized", timestamp: new Date()})
print("Test collection created")
EOF

else
    # MongoDB 5.0+
    $MONGO_SHELL --quiet --eval "
use ${DB_NAME}
try {
  db.createUser({
    user: '${DB_USER}',
    pwd: '${DB_PASSWORD}',
    roles: [
      { role: 'readWrite', db: '${DB_NAME}' },
      { role: 'dbAdmin', db: '${DB_NAME}' }
    ]
  })
  print('Database user created successfully')
} catch(e) {
  if (e.code === 51003) {
    print('User already exists, skipping...')
  } else {
    throw e
  }
}

db.createCollection('test_collection')
db.test_collection.insertOne({test: 'Database initialized', timestamp: new Date()})
print('Test collection created')
"
fi

echo "Step 7: Enabling authentication and restarting MongoDB..."

# Now enable authentication
cat > /etc/mongod.conf <<EOF
# mongod.conf - MongoDB Configuration File

# Where to store data
storage:
  dbPath: /var/lib/mongodb
  journal:
    enabled: true

# Where to write logging data
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

# Network interfaces
net:
  port: 27017
  bindIp: 127.0.0.1,${DB_SERVER_IP}

# Process management
processManagement:
  timeZoneInfo: /usr/share/zoneinfo

# Security
security:
  authorization: enabled
EOF

systemctl restart mongod

# Wait for MongoDB to restart
sleep 10

# Verify MongoDB is running
if ! systemctl is-active --quiet mongod; then
    echo "ERROR: MongoDB failed to restart. Check logs with: journalctl -u mongod -n 50"
    exit 1
fi

echo "Step 8: Testing database connection..."

# Test connection with appropriate shell
if [ "$MONGO_SHELL" = "mongo" ]; then
    $MONGO_SHELL "mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}" --quiet --eval "db.runCommand({connectionStatus: 1})" > /dev/null 2>&1
else
    $MONGO_SHELL "mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}" --quiet --eval "db.runCommand({connectionStatus: 1})" > /dev/null 2>&1
fi

if [ $? -eq 0 ]; then
    echo "✓ Database connection successful!"
else
    echo "✗ Database connection failed!"
    exit 1
fi

echo "Step 9: Configuring firewall (if UFW is installed)..."
if command -v ufw &> /dev/null; then
    ufw allow from ${APP_SERVER_IP} to any port 27017 2>/dev/null || true
    ufw reload 2>/dev/null || true
    echo "✓ Firewall rule added for ${APP_SERVER_IP}"
elif command -v firewall-cmd &> /dev/null; then
    firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${APP_SERVER_IP}/32' port protocol='tcp' port='27017' accept" 2>/dev/null || true
    firewall-cmd --reload 2>/dev/null || true
    echo "✓ Firewall rule added for ${APP_SERVER_IP}"
else
    echo "⚠ No firewall detected. Please manually configure if needed."
fi

# Save connection info to file
cat > connection-info.txt <<EOF
========================================
MongoDB Connection Information
========================================

Database Name: ${DB_NAME}
Database User: ${DB_USER}
DB Server IP: ${DB_SERVER_IP}
Port: 27017
MongoDB Version: ${MONGO_VERSION}

Connection URL for .env file:
MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}

Alternative with auth source:
MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}?authSource=${DB_NAME}

Test connection from application server:
mongo "mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}"

Generated on: $(date)
MongoDB Shell: ${MONGO_SHELL}
========================================
EOF

chmod 600 connection-info.txt

echo ""
echo "=========================================="
echo "MongoDB Configuration Completed!"
echo "=========================================="
echo ""
echo "Database Details:"
echo "  - MongoDB Version: ${MONGO_VERSION}"
echo "  - Database Name: ${DB_NAME}"
echo "  - Database User: ${DB_USER}"
echo "  - DB Server IP: ${DB_SERVER_IP}"
echo "  - Port: 27017"
echo ""
echo "Connection URL for your .env file:"
echo ""
echo "MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}"
echo ""
echo "Alternative connection string:"
echo "MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}?authSource=${DB_NAME}"
echo ""
echo "Connection information has been saved to: connection-info.txt"
echo "(This file contains your password - keep it secure!)"
echo ""
echo "MongoDB Status:"
systemctl status mongod --no-pager | head -n 15
echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Copy the MONGODB_URI above to your application's .env file on server 192.168.0.10"
echo "2. Test connection from app server: mongo \"mongodb://${DB_USER}:...@192.168.0.14:27017/${DB_NAME}\""
echo "3. Deploy your vcard application"
echo ""
