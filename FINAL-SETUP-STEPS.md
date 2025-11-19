# ✅ Final Setup Steps - MongoDB is Ready!

## Current Status

**✅ MongoDB 4.4 is successfully installed and running on your DB server!**

The installation completed successfully. You just need to run the configuration script to set up your vcard database.

## 🚀 Complete Setup Now (3 Minutes)

SSH back into your DB server (192.168.0.14) and run:

```bash
cd /home/mongodb/mongodb-installation-

# Pull the latest fix
git pull

# Run the improved configuration script
sudo ./03-configure-mongodb-v4.sh
```

### You'll be prompted for:
- **Username**: Enter `vcard` (or `thaya` or whatever you prefer)
- **Password**: Create a strong password
- **Confirm Password**: Enter the same password again

The script will:
1. ✅ Create admin user
2. ✅ Create vcard database
3. ✅ Create database user with your credentials
4. ✅ Enable authentication
5. ✅ Configure firewall for app server (192.168.0.10)
6. ✅ Generate your connection URL

## 📋 What You'll Get

After successful configuration, you'll receive:

```
MONGODB_URI=mongodb://vcard:YourPassword@192.168.0.14:27017/vcard
```

**Copy this exact line to your application's `.env` file on server 192.168.0.10**

## 🔧 Add to Your Application

On your application server (192.168.0.10), add this to your `.env` file:

```env
# MongoDB Configuration
MONGODB_URI=mongodb://vcard:YourPassword@192.168.0.14:27017/vcard
```

### For Node.js/Express:

```javascript
// Your existing code should work with this connection string
const mongoose = require('mongoose');
mongoose.connect(process.env.MONGODB_URI);
```

### For Python/Flask:

```python
from pymongo import MongoClient
import os

client = MongoClient(os.getenv('MONGODB_URI'))
db = client.vcard
```

## ✅ Test Connection from Application Server

To verify the connection works from your app server (192.168.0.10):

```bash
# Install mongo shell on app server (if not already installed)
wget -qO - https://www.mongodb.org/static/pgp/server-4.4.asc | sudo apt-key add -
echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/4.4 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-4.4.list
sudo apt-get update
sudo apt-get install -y mongodb-org-shell

# Test connection (replace with your actual credentials)
mongo "mongodb://vcard:YourPassword@192.168.0.14:27017/vcard"
```

If you see the MongoDB prompt, connection is successful!

## 🎉 You're All Set!

Your infrastructure is now complete:

- **RVP Server** (192.168.0.9): Nginx reverse proxy ✅
- **Application Server** (192.168.0.10): Your vcard application ✅
- **DB Server** (192.168.0.14): MongoDB 4.4 with vcard database ✅

## 📊 MongoDB Management Commands

```bash
# Check MongoDB status
sudo systemctl status mongod

# View MongoDB logs
sudo tail -f /var/log/mongodb/mongod.log

# Restart MongoDB
sudo systemctl restart mongod

# Connect to your database
mongo "mongodb://vcard:YourPassword@192.168.0.14:27017/vcard"
```

## 🔒 Security Notes

✅ Authentication is enabled
✅ MongoDB only listens on 127.0.0.1 and 192.168.0.14
✅ Firewall configured to allow only application server (192.168.0.10)
✅ Strong password required
✅ Connection info saved securely in `connection-info.txt` (chmod 600)

## 💾 Backup Your Database

Use the provided backup script:

```bash
sudo ./backup-database.sh
```

Backups are stored in `/backup/mongodb/` with automatic rotation.

## 🆘 If You Need Help

1. **Check MongoDB logs**: `sudo journalctl -u mongod -n 100`
2. **Test local connection**: `mongo --eval "db.version()"`
3. **Check firewall**: `sudo ufw status`
4. **Verify MongoDB is running**: `sudo systemctl status mongod`

## 📚 Additional Scripts Available

- `backup-database.sh` - Create database backups
- `restore-database.sh` - Restore from backup
- `monitor-mongodb.sh` - Health monitoring
- `test-connection.sh` - Test connection from app server
- `generate-env-config.sh` - Generate .env configuration

---

## Summary

**Your MongoDB is installed and ready!** Just run one more command:

```bash
sudo ./03-configure-mongodb-v4.sh
```

Then add the connection URL to your application's `.env` file and you're done! 🎉
