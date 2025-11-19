#!/bin/bash

###############################################################################
# MongoDB Health Monitoring Script
# Checks MongoDB status, performance, and health metrics
###############################################################################

DB_SERVER="192.168.0.14"
DB_PORT="27017"
DB_NAME="vcard"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo "MongoDB Health Monitor"
echo "==========================================${NC}"
echo ""

# Check if MongoDB service is running
echo -e "${BLUE}1. Service Status${NC}"
if systemctl is-active --quiet mongod; then
    echo -e "${GREEN}✓ MongoDB service is running${NC}"
else
    echo -e "${RED}✗ MongoDB service is NOT running${NC}"
    echo "Start it with: sudo systemctl start mongod"
    exit 1
fi
echo ""

# Check if MongoDB is listening on the correct port
echo -e "${BLUE}2. Network Listening${NC}"
if sudo netstat -tlnp 2>/dev/null | grep -q ":$DB_PORT"; then
    echo -e "${GREEN}✓ MongoDB is listening on port $DB_PORT${NC}"
    sudo netstat -tlnp | grep ":$DB_PORT" | head -n 1
elif sudo ss -tlnp 2>/dev/null | grep -q ":$DB_PORT"; then
    echo -e "${GREEN}✓ MongoDB is listening on port $DB_PORT${NC}"
    sudo ss -tlnp | grep ":$DB_PORT" | head -n 1
else
    echo -e "${YELLOW}⚠ MongoDB may not be listening on port $DB_PORT${NC}"
fi
echo ""

# Check system resources
echo -e "${BLUE}3. System Resources${NC}"
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  Load: " 100 - $1"%"}'

echo "Memory Usage:"
free -h | awk '/^Mem:/ {printf "  Used: %s / %s (%.1f%%)\n", $3, $2, $3/$2 * 100}'

echo "Disk Usage (MongoDB data):"
df -h /var/lib/mongodb 2>/dev/null | awk 'NR==2 {printf "  Used: %s / %s (%s)\n", $3, $2, $5}' || echo "  Data directory not found"
echo ""

# Check MongoDB logs for errors
echo -e "${BLUE}4. Recent Log Errors (last 10)${NC}"
ERROR_COUNT=$(sudo tail -n 100 /var/log/mongodb/mongod.log 2>/dev/null | grep -i "error\|warning" | wc -l)
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ No recent errors or warnings${NC}"
else
    echo -e "${YELLOW}⚠ Found $ERROR_COUNT error/warning entries:${NC}"
    sudo tail -n 100 /var/log/mongodb/mongod.log | grep -i "error\|warning" | tail -n 10
fi
echo ""

# MongoDB database statistics (if credentials provided)
if [ $# -eq 2 ]; then
    DB_USER="$1"
    DB_PASSWORD="$2"

    echo -e "${BLUE}5. Database Statistics${NC}"
    CONNECTION_URI="mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}"

    if command -v mongosh &> /dev/null; then
        mongosh "$CONNECTION_URI" --quiet --eval "
            print('Database: ' + db.getName());
            print('Server version: ' + db.version());
            print('');
            print('Collections:');
            db.getCollectionNames().forEach(function(col) {
                var count = db.getCollection(col).countDocuments();
                var size = db.getCollection(col).stats().size;
                print('  - ' + col + ': ' + count + ' documents (' + (size/1024/1024).toFixed(2) + ' MB)');
            });
            print('');
            var stats = db.stats();
            print('Total Database Size: ' + (stats.dataSize/1024/1024).toFixed(2) + ' MB');
            print('Storage Size: ' + (stats.storageSize/1024/1024).toFixed(2) + ' MB');
            print('Indexes Size: ' + (stats.indexSize/1024/1024).toFixed(2) + ' MB');
            print('');
            print('Connection Status:');
            var connStatus = db.runCommand({connectionStatus: 1});
            print('  Authenticated: ' + (connStatus.authInfo.authenticatedUsers.length > 0 ? 'Yes' : 'No'));
        " 2>/dev/null

        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Database statistics retrieved${NC}"
        else
            echo -e "${RED}✗ Failed to retrieve database statistics${NC}"
        fi
    else
        echo -e "${YELLOW}⚠ mongosh not installed, skipping database statistics${NC}"
    fi
    echo ""

    # Connection pool and performance
    echo -e "${BLUE}6. Server Status${NC}"
    mongosh "$CONNECTION_URI" --quiet --eval "
        var status = db.serverStatus();
        print('Uptime: ' + Math.floor(status.uptime / 3600) + ' hours');
        print('Current Connections: ' + status.connections.current);
        print('Available Connections: ' + status.connections.available);
        print('Active Clients: ' + status.globalLock.activeClients.total);
        print('Queued Operations: ' + status.globalLock.currentQueue.total);
    " 2>/dev/null
    echo ""
fi

# Summary
echo -e "${BLUE}==========================================${NC}"
if systemctl is-active --quiet mongod && [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ MongoDB is healthy${NC}"
else
    echo -e "${YELLOW}⚠ MongoDB may need attention${NC}"
fi
echo -e "${BLUE}==========================================${NC}"
echo ""
echo "Usage: $0 [username] [password]"
echo "Provide credentials for detailed database statistics"
echo ""
echo "Useful commands:"
echo "  - View logs: sudo tail -f /var/log/mongodb/mongod.log"
echo "  - Restart: sudo systemctl restart mongod"
echo "  - Check status: sudo systemctl status mongod"
