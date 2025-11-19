# ⚠️ CRITICAL FIX: Illegal Instruction Error

## Problem

You're seeing this error when trying to run MongoDB:
```
mongod
Illegal instruction (core dumped)
```

## Root Cause

**Your CPU does not support AVX instructions**, which are required by MongoDB 7.0+. This is a hardware limitation, not a software bug.

MongoDB version requirements:
- **MongoDB 7.0+**: Requires AVX instruction set (Intel Sandy Bridge or newer, AMD Bulldozer or newer)
- **MongoDB 4.4 and earlier**: No AVX requirement (works on older CPUs)

## Solution

Run the CPU compatibility fix script that will:
1. Detect your CPU capabilities
2. Install the appropriate MongoDB version for your hardware
3. Configure everything correctly

## Quick Fix (3 Commands)

On your DB server (192.168.0.14):

```bash
cd /home/mongodb/mongodb-installation-
git pull
sudo ./fix-cpu-compatibility.sh
```

That's it! The script will automatically:
- ✅ Check if your CPU supports AVX
- ✅ Remove incompatible MongoDB 7.0
- ✅ Install MongoDB 4.4 (if no AVX) or MongoDB 7.0 (if AVX supported)
- ✅ Configure and start MongoDB
- ✅ Verify everything works

## After the Fix

Once the fix completes successfully, run:

```bash
# Verify MongoDB is running
systemctl status mongod

# Test the shell (will be 'mongo' for 4.4, or 'mongosh' for 7.0+)
mongo --version
# or
mongosh --version

# Continue with configuration
sudo ./03-configure-mongodb-v3.sh
```

The configuration script (v3) now supports **both** MongoDB versions automatically!

## What You'll Get

After configuration completes, you'll receive your connection URL:

```
MONGODB_URI=mongodb://thaya:YourPassword@192.168.0.14:27017/vcard
```

Copy this to your application's `.env` file on server 192.168.0.10.

## MongoDB 4.4 vs 7.0 - Does It Matter?

**No significant impact for your vcard application!**

Both versions support:
- ✅ All standard CRUD operations
- ✅ Authentication and security
- ✅ Remote connections
- ✅ Database and user management
- ✅ Full compatibility with Node.js, Python, etc.

MongoDB 4.4:
- Released: July 2020
- Support until: February 2024 (now in extended support)
- Fully stable and production-ready
- Works on **all CPUs** (no AVX requirement)

MongoDB 7.0:
- Released: August 2023
- Latest features and performance improvements
- Requires **modern CPUs** with AVX support

## Complete Step-by-Step

```bash
# 1. Navigate to the directory
cd /home/mongodb/mongodb-installation-

# 2. Pull latest fixes
git pull

# 3. Make scripts executable
chmod +x *.sh

# 4. Run the CPU compatibility fix
sudo ./fix-cpu-compatibility.sh
```

Wait for it to complete (will show success message).

```bash
# 5. Verify installation
systemctl status mongod
mongo --version  # or mongosh --version

# 6. Configure database and create vcard
sudo ./03-configure-mongodb-v3.sh
```

Enter your credentials:
- Username: `thaya` (or any name you want)
- Password: Create a strong password

```bash
# 7. You'll receive your connection URL
# Copy this to your application's .env file
```

## Troubleshooting

### If the fix script fails:

```bash
# Check the logs
sudo journalctl -u mongod -n 100

# Try manual cleanup and retry
sudo systemctl stop mongod
sudo apt-get purge -y mongodb-org*
sudo rm -rf /var/lib/mongodb /var/log/mongodb
sudo ./fix-cpu-compatibility.sh
```

### To verify CPU capabilities manually:

```bash
# Check for AVX support
grep avx /proc/cpuinfo

# If output is empty = No AVX support = Need MongoDB 4.4
# If output shows 'avx' flags = AVX supported = Can use MongoDB 7.0
```

## Technical Details

The "Illegal instruction" error occurs because:
1. MongoDB 7.0 binaries are compiled with AVX instructions
2. When executed on a CPU without AVX, the CPU encounters an instruction it doesn't understand
3. This causes a hardware exception (SIGILL signal)
4. The kernel terminates the process with "Illegal instruction (core dumped)"

This is not a bug - it's a CPU architecture mismatch. The fix installs the correct MongoDB version for your CPU.

## References

- [MongoDB CPU Requirements](https://www.mongodb.com/docs/manual/administration/production-notes/#x86_64)
- [MongoDB 7.0 Release Notes](https://www.mongodb.com/docs/manual/release-notes/7.0/)
- [MongoDB 4.4 Documentation](https://www.mongodb.com/docs/v4.4/)

---

**Need help?** If the automatic fix doesn't work, check:
1. CPU info: `lscpu | grep -i avx`
2. MongoDB logs: `sudo tail -100 /var/log/mongodb/mongod.log`
3. System logs: `sudo journalctl -u mongod -n 100`
