# MongoDB Installation Guide for DB Server (192.168.0.14)

Complete MongoDB setup scripts for vcard database deployment on your infrastructure.

## Infrastructure Overview

- **RVP Server**: `192.168.0.9` - Nginx reverse proxy (CLI and web)
- **Application Server**: `192.168.0.10` - Application hosting
- **DB Server**: `192.168.0.14` - MongoDB database (THIS SETUP)

## What This Does

This setup will:
1. ✅ Completely remove any existing MongoDB installations
2. ✅ Clean up all MongoDB-related files and configurations
3. ✅ Install MongoDB Community Edition 7.0 (latest stable)
4. ✅ Configure MongoDB for remote access from application server
5. ✅ Enable authentication and security
6. ✅ Create `vcard` database with dedicated user
7. ✅ Configure firewall rules (if applicable)
8. ✅ Provide connection URL for your application

## Quick Start (Recommended)

### Option 1: Run Complete Setup (All-in-One)

```bash
# Copy all scripts to your DB server (192.168.0.14)
# Then run:
chmod +x *.sh
sudo ./setup-mongodb-complete.sh
```

This will guide you through all steps interactively.

### Option 2: Run Individual Scripts

If you prefer step-by-step control:

```bash
# Make all scripts executable
chmod +x *.sh

# Step 1: Cleanup existing MongoDB
sudo ./01-cleanup-mongodb.sh

# Step 2: Install MongoDB fresh
sudo ./02-install-mongodb.sh

# Step 3: Configure and secure MongoDB
sudo ./03-configure-mongodb.sh
```

## Detailed Instructions

### Prerequisites

- Root or sudo access on DB server (192.168.0.14)
- Internet connection for downloading MongoDB packages
- Supported OS: Ubuntu 20.04+, Debian 10+, CentOS/RHEL 8+

### Step-by-Step Setup

#### 1. Transfer Scripts to DB Server

```bash
# From your local machine or wherever you have these scripts
scp -r *.sh user@192.168.0.14:/tmp/mongodb-setup/

# SSH into DB server
ssh user@192.168.0.14
cd /tmp/mongodb-setup
```

#### 2. Run the Setup

```bash
# Make scripts executable
chmod +x *.sh

# Run the complete setup
sudo ./setup-mongodb-complete.sh
```

#### 3. During Configuration

You'll be prompted to create database credentials:
- **Username**: Default is `vcardadmin` (or enter your own)
- **Password**: Choose a strong password
- **Confirmation**: Re-enter the same password

#### 4. Get Your Connection String

At the end of the setup, you'll receive a connection URL like:

```
mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard
```

Or with auth source specified:

```
mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard?authSource=vcard
```

## Application Configuration

### Add to .env File on Application Server (192.168.0.10)

```env
# MongoDB Configuration
MONGODB_URI=mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard
DB_NAME=vcard
```

### Node.js Connection Example

```javascript
const mongoose = require('mongoose');

mongoose.connect(process.env.MONGODB_URI, {
  useNewUrlParser: true,
  useUnifiedTopology: true,
})
.then(() => console.log('Connected to MongoDB'))
.catch(err => console.error('MongoDB connection error:', err));
```

### Python Connection Example

```python
from pymongo import MongoClient

client = MongoClient('mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard')
db = client.vcard
```

## Verification

### Test Connection from DB Server

```bash
# Connect using mongosh
mongosh "mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard"

# Once connected, verify database
show dbs
use vcard
show collections
```

### Test Connection from Application Server

```bash
# Install mongosh on application server if needed
# Ubuntu/Debian:
wget -qO - https://www.mongodb.org/static/pgp/server-7.0.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
sudo apt-get update
sudo apt-get install -y mongodb-mongosh

# Test connection
mongosh "mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard"
```

## Firewall Configuration

### If Using UFW (Ubuntu/Debian)

The script automatically adds this rule:

```bash
sudo ufw allow from 192.168.0.10 to any port 27017
```

To manually verify:

```bash
sudo ufw status
```

### If Using firewalld (CentOS/RHEL)

The script automatically adds this rule:

```bash
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.0.10/32' port protocol='tcp' port='27017' accept"
sudo firewall-cmd --reload
```

To manually verify:

```bash
sudo firewall-cmd --list-all
```

### Manual iptables Rule

If you need to add manually:

```bash
sudo iptables -A INPUT -p tcp -s 192.168.0.10 --dport 27017 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 27017 -j DROP
```

## MongoDB Management

### Useful Commands

```bash
# Check MongoDB status
sudo systemctl status mongod

# Start MongoDB
sudo systemctl start mongod

# Stop MongoDB
sudo systemctl stop mongod

# Restart MongoDB
sudo systemctl restart mongod

# Enable MongoDB on boot
sudo systemctl enable mongod

# View logs
sudo tail -f /var/log/mongodb/mongod.log

# View real-time logs
sudo journalctl -u mongod -f
```

### MongoDB Shell Commands

```javascript
// Show all databases
show dbs

// Switch to vcard database
use vcard

// Show collections
show collections

// Show users
db.getUsers()

// Database statistics
db.stats()

// Check server status
db.serverStatus()

// Create a new collection
db.createCollection("mycollection")

// Insert a document
db.mycollection.insertOne({name: "Test", created: new Date()})

// Find documents
db.mycollection.find()
```

## Security Best Practices

### 1. Change Default Passwords

After initial setup, consider rotating passwords:

```javascript
use vcard
db.changeUserPassword("vcardadmin", "NewStrongPassword123!")
```

### 2. Network Security

- MongoDB is configured to listen on `127.0.0.1` and `192.168.0.14` only
- Firewall rules restrict access to application server only
- Authentication is required for all connections

### 3. Backup Strategy

Create regular backups:

```bash
# Backup vcard database
mongodump --uri="mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard" --out=/backup/mongodb/$(date +%Y%m%d)

# Restore from backup
mongorestore --uri="mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard" /backup/mongodb/20240101/vcard
```

### 4. Monitoring

```bash
# Monitor MongoDB performance
mongosh "mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard" --eval "db.currentOp()"

# Check database size
mongosh "mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard" --eval "db.stats()"
```

## Troubleshooting

### MongoDB Won't Start

```bash
# Check logs
sudo journalctl -u mongod -n 100 --no-pager

# Check configuration
sudo cat /etc/mongod.conf

# Check permissions
ls -la /var/lib/mongodb
ls -la /var/log/mongodb

# Fix permissions if needed
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo chown -R mongodb:mongodb /var/log/mongodb
```

### Cannot Connect from Application Server

```bash
# On DB Server: Check if MongoDB is listening
sudo netstat -tlnp | grep 27017
# Or
sudo ss -tlnp | grep 27017

# Test connectivity from application server
telnet 192.168.0.14 27017
# Or
nc -zv 192.168.0.14 27017

# Check firewall
sudo ufw status
# Or
sudo firewall-cmd --list-all
```

### Authentication Failed

```bash
# Verify user exists
mongosh --quiet --eval "db.getUsers()" mongodb://localhost:27017/vcard

# Check password (make sure there are no hidden characters)
# Recreate user if needed:
mongosh "mongodb://admin:AdminPassword@192.168.0.14:27017/admin" --eval '
use vcard
db.dropUser("vcardadmin")
db.createUser({user: "vcardadmin", pwd: "NewPassword", roles: [{role: "readWrite", db: "vcard"}]})
'
```

### Port Already in Use

```bash
# Find what's using port 27017
sudo lsof -i :27017

# Kill the process if needed
sudo kill -9 <PID>
```

## Scripts Overview

| Script | Purpose |
|--------|---------|
| `setup-mongodb-complete.sh` | Master script - runs all steps |
| `01-cleanup-mongodb.sh` | Removes existing MongoDB installations |
| `02-install-mongodb.sh` | Installs MongoDB Community Edition 7.0 |
| `03-configure-mongodb.sh` | Configures security, creates vcard DB |

## Additional Resources

- [MongoDB Official Documentation](https://docs.mongodb.com/)
- [MongoDB Security Checklist](https://docs.mongodb.com/manual/administration/security-checklist/)
- [MongoDB Connection String URI Format](https://docs.mongodb.com/manual/reference/connection-string/)
- [MongoDB Best Practices](https://docs.mongodb.com/manual/administration/production-notes/)

## Support

If you encounter issues:

1. Check the logs: `sudo journalctl -u mongod -n 100`
2. Verify configuration: `sudo cat /etc/mongod.conf`
3. Test network connectivity: `telnet 192.168.0.14 27017`
4. Check firewall rules: `sudo ufw status` or `sudo firewall-cmd --list-all`

## License

These scripts are provided as-is for deployment purposes.

---

**Important Notes:**
- Always backup your data before running cleanup scripts
- Store database credentials securely
- Rotate passwords regularly
- Monitor MongoDB logs for suspicious activity
- Keep MongoDB updated with security patches
