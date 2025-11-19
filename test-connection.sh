#!/bin/bash

###############################################################################
# MongoDB Connection Test Script
# Tests connection from Application Server to DB Server
###############################################################################

DB_SERVER="192.168.0.14"
DB_PORT="27017"
DB_NAME="vcard"

echo "=========================================="
echo "MongoDB Connection Test"
echo "=========================================="
echo ""

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

# Test 1: Network connectivity
echo "Test 1: Network connectivity to $DB_SERVER:$DB_PORT"
if command -v nc &> /dev/null; then
    nc -zv $DB_SERVER $DB_PORT 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Network connection successful"
    else
        echo "✗ Cannot reach $DB_SERVER:$DB_PORT"
        echo "Check firewall rules and network configuration"
        exit 1
    fi
elif command -v telnet &> /dev/null; then
    timeout 5 telnet $DB_SERVER $DB_PORT 2>&1
    if [ $? -eq 0 ]; then
        echo "✓ Network connection successful"
    else
        echo "✗ Cannot reach $DB_SERVER:$DB_PORT"
        exit 1
    fi
else
    echo "⚠ nc or telnet not found, skipping network test"
fi
echo ""

# Test 2: MongoDB connection
echo "Test 2: MongoDB authentication and database access"
CONNECTION_URI="mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}"

if command -v mongosh &> /dev/null; then
    echo "Using mongosh to test connection..."
    mongosh "$CONNECTION_URI" --quiet --eval "
        print('✓ Successfully connected to MongoDB');
        print('Database: ' + db.getName());
        print('Server version: ' + db.version());
        print('Collections: ' + db.getCollectionNames().join(', '));
    "

    if [ $? -eq 0 ]; then
        echo ""
        echo "✓ All tests passed!"
        echo ""
        echo "Connection string for .env file:"
        echo "MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}"
    else
        echo "✗ MongoDB connection failed"
        echo "Check username, password, and MongoDB configuration"
        exit 1
    fi
else
    echo "⚠ mongosh not found on this system"
    echo "Install it with: sudo apt-get install -y mongodb-mongosh"
    echo ""
    echo "Your connection string would be:"
    echo "mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}"
fi

echo ""
echo "=========================================="
