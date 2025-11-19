# Quick Start Guide

## 🚀 3-Step MongoDB Setup

### Step 1: Copy Scripts to DB Server

```bash
# Transfer all files to DB server (192.168.0.14)
scp -r * user@192.168.0.14:/tmp/mongodb-setup/
ssh user@192.168.0.14
cd /tmp/mongodb-setup
```

### Step 2: Run Setup

```bash
# Make executable and run
chmod +x *.sh
sudo ./setup-mongodb-complete.sh
```

You'll be prompted for:
- Database username (default: vcardadmin)
- Database password (create a strong one)

### Step 3: Get Connection URL

At the end, you'll receive:

```
MONGODB_URI=mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard
```

Copy this to your application's `.env` file on server 192.168.0.10.

## ✅ Test Connection

From application server (192.168.0.10):

```bash
# Copy test script
scp user@192.168.0.14:/tmp/mongodb-setup/test-connection.sh .

# Run test
chmod +x test-connection.sh
./test-connection.sh
```

## 📦 What Gets Installed

- MongoDB Community Edition 7.0 (latest stable)
- Configured for remote access from 192.168.0.10
- Authentication enabled
- Database: `vcard`
- Firewall rules configured

## 🔧 Useful Scripts

| Script | Purpose |
|--------|---------|
| `setup-mongodb-complete.sh` | **Main setup** - Run this first |
| `test-connection.sh` | Test connection from app server |
| `backup-database.sh` | Create database backup |
| `restore-database.sh` | Restore from backup |
| `monitor-mongodb.sh` | Health check and monitoring |
| `generate-env-config.sh` | Generate .env configuration |

## 📱 Application Setup

### Node.js/Express Example

```javascript
// .env file
MONGODB_URI=mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard

// app.js
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGODB_URI);
```

### Python/Flask Example

```python
# .env file
MONGODB_URI=mongodb://vcardadmin:YourPassword@192.168.0.14:27017/vcard

# app.py
from pymongo import MongoClient
import os

client = MongoClient(os.getenv('MONGODB_URI'))
db = client.vcard
```

## 🆘 Common Issues

### Can't connect from app server?

```bash
# On DB server, check if MongoDB is listening
sudo netstat -tlnp | grep 27017

# Check firewall
sudo ufw status
```

### MongoDB won't start?

```bash
# Check logs
sudo journalctl -u mongod -n 50

# Check permissions
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo systemctl restart mongod
```

### Authentication failed?

Make sure:
- Username is correct
- Password has no spaces
- Using correct database name: `vcard`

## 📚 Full Documentation

See [README.md](README.md) for complete documentation.

## 🔐 Security Checklist

- ✅ Authentication enabled
- ✅ Firewall configured for app server only
- ✅ Binding to specific IPs only
- ⚠️ Change password after setup (recommended)
- ⚠️ Setup regular backups (use backup-database.sh)
- ⚠️ Monitor logs regularly (use monitor-mongodb.sh)

## 💾 Backup Schedule

Setup automated backups (recommended):

```bash
# Add to crontab
sudo crontab -e

# Backup daily at 2 AM
0 2 * * * /path/to/backup-database.sh <<EOF
vcardadmin
YourPassword
EOF
```

## 📊 Monitoring

```bash
# Quick health check
./monitor-mongodb.sh vcardadmin YourPassword

# Watch logs in real-time
sudo tail -f /var/log/mongodb/mongod.log

# Check service status
sudo systemctl status mongod
```

---

**Need help?** Check the full README.md or MongoDB logs: `sudo journalctl -u mongod -f`
