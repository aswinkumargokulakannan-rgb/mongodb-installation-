#!/bin/bash

###############################################################################
# Generate .env Configuration for Application Server
# Creates MongoDB connection configuration for your application
###############################################################################

DB_SERVER="192.168.0.14"
DB_PORT="27017"
DB_NAME="vcard"

echo "=========================================="
echo "MongoDB .env Configuration Generator"
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

# Generate the configuration
OUTPUT_FILE="mongodb-config.env"

cat > "$OUTPUT_FILE" <<EOF
# ============================================
# MongoDB Configuration for vcard Application
# Generated on: $(date)
# ============================================

# MongoDB Connection URI
MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}

# Alternative with authSource (use if the above doesn't work)
# MONGODB_URI=mongodb://${DB_USER}:${DB_PASSWORD}@${DB_SERVER}:${DB_PORT}/${DB_NAME}?authSource=${DB_NAME}

# Individual Connection Parameters (if your app needs them separately)
DB_HOST=${DB_SERVER}
DB_PORT=${DB_PORT}
DB_NAME=${DB_NAME}
DB_USER=${DB_USER}
DB_PASSWORD=${DB_PASSWORD}

# MongoDB Options (uncomment and adjust as needed)
# DB_POOL_SIZE=10
# DB_TIMEOUT=30000
# DB_SSL=false
# DB_RETRY_WRITES=true

# ============================================
# Usage Instructions:
# 1. Copy the MONGODB_URI line to your .env file on the application server (192.168.0.10)
# 2. Ensure no spaces around the = sign
# 3. Do not commit this file to version control
# 4. Test the connection before deploying to production
# ============================================
EOF

echo "✓ Configuration generated: $OUTPUT_FILE"
echo ""
echo "=========================================="
echo "Configuration Content:"
echo "=========================================="
cat "$OUTPUT_FILE"
echo ""
echo "=========================================="
echo ""
echo "Next Steps:"
echo "1. Copy $OUTPUT_FILE to your application server (192.168.0.10)"
echo "   scp $OUTPUT_FILE user@192.168.0.10:/path/to/your/app/"
echo ""
echo "2. Add the MONGODB_URI to your application's .env file:"
echo "   cat mongodb-config.env >> /path/to/your/app/.env"
echo ""
echo "3. Test the connection using test-connection.sh"
echo ""
echo "⚠ IMPORTANT: Keep this file secure and do not commit to git!"
echo "   Add to .gitignore: echo 'mongodb-config.env' >> .gitignore"
echo ""

# Create a .env.example file without sensitive data
cat > ".env.example" <<EOF
# MongoDB Configuration
MONGODB_URI=mongodb://username:password@192.168.0.14:27017/vcard

# Individual Connection Parameters
DB_HOST=192.168.0.14
DB_PORT=27017
DB_NAME=vcard
DB_USER=your_username
DB_PASSWORD=your_password
EOF

echo "✓ Created .env.example (template without real credentials)"
echo ""
