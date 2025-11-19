# MongoDB Installation Troubleshooting Guide

## Issue: "mongod: command not found" or "mongosh: command not found"

This error occurs when MongoDB packages are installed but the binaries are not in your system's PATH.

### Quick Fix (Recommended)

Run this on your DB server (192.168.0.14):

```bash
cd /home/mongodb/mongodb-installation-

# Pull latest fixes
git pull

# Make the fix script executable
chmod +x quick-fix-install.sh

# Run the quick fix
sudo ./quick-fix-install.sh
```

After the fix completes, verify:

```bash
mongod --version
mongosh --version
```

Both commands should now work without errors.

### Continue Setup

Once the fix is applied, run the updated configuration script:

```bash
sudo ./03-configure-mongodb-v2.sh
```

This improved version:
- ✅ Automatically finds MongoDB binaries even if not in PATH
- ✅ Better error handling
- ✅ More reliable startup verification
- ✅ Saves connection info to a file

---

## Alternative: Full Diagnostic Fix

If the quick fix doesn't work, use the full diagnostic script:

```bash
sudo ./fix-mongodb-path.sh
```

This script will:
1. Search for MongoDB binaries across the system
2. Reinstall packages if needed
3. Create symbolic links if necessary
4. Verify all components

---

## Manual Fix Steps

If automated fixes don't work, try these manual steps:

### Step 1: Verify Package Installation

```bash
dpkg -l | grep mongodb
```

You should see packages like:
- mongodb-org
- mongodb-org-server
- mongodb-mongosh

### Step 2: Find MongoDB Binaries

```bash
# Find mongod
find /usr -name mongod -type f 2>/dev/null

# Find mongosh
find /usr -name mongosh -type f 2>/dev/null
```

### Step 3: Reinstall MongoDB Packages

```bash
sudo apt-get update
sudo apt-get install --reinstall -y mongodb-org mongodb-mongosh
```

### Step 4: Verify Installation

```bash
which mongod
which mongosh
```

If these return paths, you're good to go!

### Step 5: Add to PATH if Needed

If binaries are found but not in PATH:

```bash
# Create symbolic links (adjust paths as needed)
sudo ln -sf /path/to/mongod /usr/bin/mongod
sudo ln -sf /path/to/mongosh /usr/bin/mongosh
```

---

## After Fixing PATH Issues

Continue with MongoDB configuration:

```bash
# Use the improved v2 configuration script
sudo ./03-configure-mongodb-v2.sh
```

You'll be prompted for:
- Database username (default: vcardadmin)
- Database password (create a strong one)

At the end, you'll receive your connection URL:

```
MONGODB_URI=mongodb://username:password@192.168.0.14:27017/vcard
```

---

## Common Issues After PATH Fix

### MongoDB Won't Start

```bash
# Check status
sudo systemctl status mongod

# View logs
sudo journalctl -u mongod -n 50

# Check permissions
sudo chown -R mongodb:mongodb /var/lib/mongodb
sudo chown -R mongodb:mongodb /var/log/mongodb

# Restart
sudo systemctl restart mongod
```

### Connection Test Fails

```bash
# Verify MongoDB is listening
sudo ss -tlnp | grep 27017

# Check firewall
sudo ufw status

# Test local connection
mongosh "mongodb://localhost:27017"
```

### Authentication Issues

If you get authentication errors after setup:

```bash
# Connect without auth (only works locally before auth is enabled)
mongosh "mongodb://localhost:27017"

# Or with credentials
mongosh "mongodb://username:password@192.168.0.14:27017/vcard"
```

---

## Contact Support

If none of these fixes work:

1. Check MongoDB logs:
   ```bash
   sudo tail -100 /var/log/mongodb/mongod.log
   ```

2. Check system logs:
   ```bash
   sudo journalctl -u mongod -n 100
   ```

3. Verify OS compatibility:
   ```bash
   lsb_release -a
   ```

MongoDB 7.0 supports:
- Ubuntu 20.04 (Focal) and 22.04 (Jammy)
- Debian 10 (Buster) and 11 (Bullseye)
- RHEL/CentOS 8 and 9

---

## Quick Reference Commands

```bash
# Check MongoDB status
sudo systemctl status mongod

# Start MongoDB
sudo systemctl start mongod

# Stop MongoDB
sudo systemctl stop mongod

# Restart MongoDB
sudo systemctl restart mongod

# View logs
sudo tail -f /var/log/mongodb/mongod.log

# Test connection
mongosh "mongodb://user:pass@192.168.0.14:27017/vcard"
```
