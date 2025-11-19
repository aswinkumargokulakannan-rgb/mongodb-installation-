#!/bin/bash

###############################################################################
# MongoDB Fresh Installation Script for DB Server (192.168.0.14)
# This script installs MongoDB Community Edition (Latest Stable Version)
###############################################################################

set -e

echo "=========================================="
echo "MongoDB Fresh Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    VER=$VERSION_ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

echo "Detected OS: $OS $VER"
echo ""

if [[ "$OS" == "ubuntu" ]] || [[ "$OS" == "debian" ]]; then
    echo "Step 1: Installing required dependencies..."
    apt-get update
    apt-get install -y gnupg curl wget

    echo "Step 2: Adding MongoDB GPG key..."
    curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
        gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor

    echo "Step 3: Adding MongoDB repository..."
    if [[ "$OS" == "ubuntu" ]]; then
        # Determine Ubuntu version
        if [[ "$VER" == "22.04" ]]; then
            CODENAME="jammy"
        elif [[ "$VER" == "20.04" ]]; then
            CODENAME="focal"
        else
            CODENAME=$(lsb_release -cs)
        fi
        echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu $CODENAME/mongodb-org/7.0 multiverse" | \
            tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    else
        # Debian
        echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | \
            tee /etc/apt/sources.list.d/mongodb-org-7.0.list
    fi

    echo "Step 4: Updating package database..."
    apt-get update

    echo "Step 5: Installing MongoDB..."
    apt-get install -y mongodb-org

elif [[ "$OS" == "centos" ]] || [[ "$OS" == "rhel" ]] || [[ "$OS" == "rocky" ]] || [[ "$OS" == "almalinux" ]]; then
    echo "Step 1: Creating MongoDB repository file..."
    cat > /etc/yum.repos.d/mongodb-org-7.0.repo <<EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/\$releasever/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF

    echo "Step 2: Installing MongoDB..."
    yum install -y mongodb-org

else
    echo "Unsupported OS: $OS"
    exit 1
fi

echo "Step 6: Creating MongoDB data directory..."
mkdir -p /var/lib/mongodb
mkdir -p /var/log/mongodb

echo "Step 7: Setting proper permissions..."
chown -R mongodb:mongodb /var/lib/mongodb
chown -R mongodb:mongodb /var/log/mongodb
chmod 755 /var/lib/mongodb
chmod 755 /var/log/mongodb

echo "Step 8: Enabling MongoDB to start on boot..."
systemctl daemon-reload
systemctl enable mongod

echo ""
echo "=========================================="
echo "MongoDB Installation Completed!"
echo "=========================================="
echo ""
mongod --version
echo ""
echo "MongoDB is installed but NOT started yet."
echo "Configuration will be done in the next step."
