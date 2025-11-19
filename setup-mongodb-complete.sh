#!/bin/bash

###############################################################################
# MongoDB Complete Setup Master Script
#
# This script performs a complete MongoDB installation on DB Server 192.168.0.14:
# 1. Removes all existing MongoDB installations
# 2. Installs MongoDB Community Edition fresh
# 3. Configures for remote access from Application Server 192.168.0.10
# 4. Creates 'vcard' database with authentication
# 5. Provides connection URL for application .env file
#
# Usage: sudo ./setup-mongodb-complete.sh
###############################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}ERROR: This script must be run as root or with sudo${NC}"
    echo "Usage: sudo $0"
    exit 1
fi

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║         MongoDB Complete Setup for DB Server                  ║"
echo "║              192.168.0.14 (vcard database)                    ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Warning message
echo -e "${YELLOW}WARNING: This script will:${NC}"
echo "  1. COMPLETELY REMOVE any existing MongoDB installation"
echo "  2. DELETE all existing MongoDB data and configurations"
echo "  3. Install MongoDB Community Edition fresh"
echo "  4. Configure MongoDB for remote access"
echo "  5. Create 'vcard' database with authentication"
echo ""
read -p "Do you want to continue? (yes/no): " CONFIRM

if [[ ! "$CONFIRM" =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Installation cancelled."
    exit 0
fi

echo ""
echo -e "${GREEN}Starting MongoDB Complete Setup...${NC}"
echo ""

# Step 1: Cleanup
echo -e "${BLUE}[1/3] Running MongoDB Cleanup...${NC}"
if [ -f "$SCRIPT_DIR/01-cleanup-mongodb.sh" ]; then
    bash "$SCRIPT_DIR/01-cleanup-mongodb.sh"
else
    echo -e "${RED}ERROR: Cleanup script not found at $SCRIPT_DIR/01-cleanup-mongodb.sh${NC}"
    exit 1
fi

echo ""
read -p "Press Enter to continue to installation..."
echo ""

# Step 2: Installation
echo -e "${BLUE}[2/3] Running MongoDB Installation...${NC}"
if [ -f "$SCRIPT_DIR/02-install-mongodb.sh" ]; then
    bash "$SCRIPT_DIR/02-install-mongodb.sh"
else
    echo -e "${RED}ERROR: Installation script not found at $SCRIPT_DIR/02-install-mongodb.sh${NC}"
    exit 1
fi

echo ""
read -p "Press Enter to continue to configuration..."
echo ""

# Step 3: Configuration
echo -e "${BLUE}[3/3] Running MongoDB Configuration...${NC}"
if [ -f "$SCRIPT_DIR/03-configure-mongodb.sh" ]; then
    bash "$SCRIPT_DIR/03-configure-mongodb.sh"
else
    echo -e "${RED}ERROR: Configuration script not found at $SCRIPT_DIR/03-configure-mongodb.sh${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                                                                ║"
echo "║              MongoDB Setup Completed Successfully!            ║"
echo "║                                                                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}Next Steps:${NC}"
echo "  1. Copy the MONGODB_URI from above to your application's .env file on 192.168.0.10"
echo "  2. Ensure your application server can reach this DB server on port 27017"
echo "  3. Test the connection from your application"
echo ""
echo "Useful Commands:"
echo "  - Check MongoDB status: systemctl status mongod"
echo "  - View MongoDB logs: tail -f /var/log/mongodb/mongod.log"
echo "  - Connect to MongoDB: mongosh 'mongodb://<user>:<password>@192.168.0.14:27017/vcard'"
echo "  - Restart MongoDB: systemctl restart mongod"
echo ""
