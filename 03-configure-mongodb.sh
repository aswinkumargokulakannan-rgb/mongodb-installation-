#!/bin/bash

###############################################################################
# MongoDB Configuration and Security Setup Script
# Configures MongoDB for remote access from Application Server (192.168.0.10)
# Creates 'vcard' database with authentication
###############################################################################

set -e

echo "=========================================="
echo "MongoDB Configuration Script"
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

echo "Step 2: Creating MongoDB configuration file..."
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
  fork: false

# Security
security:
  authorization: enabled

# Operation profiling
#operationProfiling:

# Replication
#replication:

# Sharding
#sharding:
EOF

echo "Step 3: Setting proper permissions on configuration file..."
chmod 644 /etc/mongod.conf
chown mongodb:mongodb /etc/mongod.conf

echo "Step 4: Starting MongoDB without authentication to create admin user..."
systemctl start mongod

# Wait for MongoDB to start
echo "Waiting for MongoDB to start..."
sleep 5

# Check if MongoDB is running
if ! systemctl is-active --quiet mongod; then
    echo "ERROR: MongoDB failed to start. Check logs with: journalctl -u mongod -n 50"
    exit 1
fi

echo "Step 5: Creating MongoDB admin user..."
mongosh --quiet <<EOF
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
EOF

echo "Step 6: Creating 'vcard' database and user..."
mongosh --quiet <<EOF
use ${DB_NAME}
db.createUser({
  user: "${DB_USER}",
  pwd: "${DB_PASSWORD}",
  roles: [
    { role: "readWrite", db: "${DB_NAME}" },
    { role: "dbAdmin", db: "${DB_NAME}" }
  ]
})

// Create a test collection to initialize the database
db.createCollection("test_collection")
db.test_collection.insertOne({test: "Database initialized", timestamp: new Date()})
EOF

echo "Step 7: Restarting MongoDB with authentication enabled..."
systemctl restart mongod

# Wait for MongoDB to restart
sleep 5

# Verify MongoDB is running
if ! systemctl is-active --quiet mongod; then
    echo "ERROR: MongoDB failed to restart. Check logs with: journalctl -u mongod -n 50"
    exit 1
fi

echo "Step 8: Testing database connection..."
mongosh "mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}" --quiet --eval "db.runCommand({connectionStatus: 1})" > /dev/null

if [ $? -eq 0 ]; then
    echo "✓ Database connection successful!"
else
    echo "✗ Database connection failed!"
    exit 1
fi

echo "Step 9: Configuring firewall (if UFW is installed)..."
if command -v ufw &> /dev/null; then
    # Allow MongoDB port from application server
    ufw allow from ${APP_SERVER_IP} to any port 27017
    ufw reload 2>/dev/null || true
    echo "✓ Firewall rule added for ${APP_SERVER_IP}"
elif command -v firewall-cmd &> /dev/null; then
    # For firewalld (CentOS/RHEL)
    firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='${APP_SERVER_IP}/32' port protocol='tcp' port='27017' accept"
    firewall-cmd --reload
    echo "✓ Firewall rule added for ${APP_SERVER_IP}"
else
    echo "⚠ No firewall detected (UFW or firewalld). Please manually configure firewall if needed."
fi

echo ""
echo "=========================================="
echo "MongoDB Configuration Completed!"
echo "=========================================="
echo ""
echo "Database Details:"
echo "  - Database Name: ${DB_NAME}"
echo "  - Database User: ${DB_USER}"
echo "  - DB Server IP: ${DB_SERVER_IP}"
echo "  - Port: 27017"
echo ""
echo "Connection URL for your .env file:"
echo ""
echo "MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}"
echo ""
echo "Alternative connection string with auth source:"
echo "MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER_IP}:27017/${DB_NAME}?authSource=${DB_NAME}"
echo ""
echo "MongoDB Status:"
systemctl status mongod --no-pager
echo ""
echo "To save these credentials, see the generated connection-info.txt file"
