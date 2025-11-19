#!/bin/bash

###############################################################################
# MongoDB Complete Cleanup Script for DB Server (192.168.0.14)
# This script removes all existing MongoDB installations and related files
###############################################################################

set -e

echo "=========================================="
echo "MongoDB Complete Cleanup Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root or with sudo"
    exit 1
fi

echo "Step 1: Stopping MongoDB services..."
systemctl stop mongod 2>/dev/null || true
systemctl stop mongodb 2>/dev/null || true
systemctl disable mongod 2>/dev/null || true
systemctl disable mongodb 2>/dev/null || true

echo "Step 2: Removing MongoDB packages..."
# Remove MongoDB packages for Ubuntu/Debian
apt-get purge -y mongodb-org* mongodb* 2>/dev/null || true

# Remove for Red Hat/CentOS
yum remove -y mongodb-org* mongodb* 2>/dev/null || true

echo "Step 3: Removing MongoDB data directories..."
rm -rf /var/log/mongodb
rm -rf /var/lib/mongodb
rm -rf /var/lib/mongo
rm -rf /data/db

echo "Step 4: Removing MongoDB configuration files..."
rm -rf /etc/mongod.conf
rm -rf /etc/mongodb.conf
rm -rf /etc/mongodb
rm -rf /etc/mongod.conf.d

echo "Step 5: Removing MongoDB user and group..."
userdel mongodb 2>/dev/null || true
groupdel mongodb 2>/dev/null || true

echo "Step 6: Removing MongoDB repository configurations..."
rm -f /etc/apt/sources.list.d/mongodb*.list
rm -f /etc/yum.repos.d/mongodb*.repo

echo "Step 7: Cleaning package cache..."
apt-get autoremove -y 2>/dev/null || true
apt-get autoclean -y 2>/dev/null || true
yum clean all 2>/dev/null || true

echo "Step 8: Removing leftover files..."
find /usr -name "*mongo*" -type f -delete 2>/dev/null || true
find /usr -name "*mongo*" -type d -exec rm -rf {} + 2>/dev/null || true

echo ""
echo "=========================================="
echo "MongoDB Cleanup Completed Successfully!"
echo "=========================================="
echo ""
echo "System is now ready for fresh MongoDB installation."
