# Bulletproof Deployment Guide

## 🎯 Overview
Both `pbs-utils` and `pve-utils` are now bulletproof with comprehensive error handling, validation, and clear feedback.

## 📁 Repository Structure

```
pbs-utils/
├── 00-env.sh              # Central configuration
├── 05-preflight.sh        # Environment validation
├── 10-pbs-user-token.sh   # PBS user/token creation
├── 30-pbs-acl.sh         # Permissions setup
├── 40-pve-add-storage.sh  # PVE storage configuration
├── 50-pbs-policies.sh     # Backup policies
├── 60-pbs-gc-and-scrub.sh # Maintenance jobs
├── 70-test.sh            # Health checks
├── 80-pve-jobs.sh        # Backup job creation
├── 81-pve-discover-vms.sh # Auto VM discovery
└── pve-utils/
    ├── 00-setup-all.sh    # Complete PVE setup
    ├── 10-post-install.sh # Post-install configuration
    ├── 20-microcode.sh    # Microcode updates
    ├── 30-netdata.sh      # Monitoring setup
    └── 40-kernel-clean.sh # Kernel cleanup
```

## 🚀 Quick Deployment

### For New PVE Nodes

```bash
# 1. Copy repository to PVE node
scp -r pbs-utils root@NEW_PVE_NODE:~/

# 2. SSH to PVE node and setup
ssh root@NEW_PVE_NODE
cd ~/pbs-utils

# 3. Run PVE utilities (optional but recommended)
cd pve-utils
./00-setup-all.sh

# 4. Configure PBS storage
cd ..
export PBS_SECRET="6868ee30-ca08-4547-90c7-6f58bc862228"
./05-preflight.sh
./40-pve-add-storage.sh

# 5. Create backup jobs
./80-pve-jobs.sh --name nightly-infra --store pbs-infra --vm "100,101,102" --schedule "daily"
```

### For New PBS Servers

```bash
# 1. Copy repository to PBS server
scp -r pbs-utils root@NEW_PBS_HOST:~/

# 2. SSH to PBS server and setup
ssh root@NEW_PBS_HOST
cd ~/pbs-utils

# 3. Update configuration for new PBS host
vim 00-env.sh  # Set PBS_HOST to new server IP/hostname

# 4. Run PBS setup sequence
./05-preflight.sh
./10-pbs-user-token.sh    # SAVE THE TOKEN SECRET!
./30-pbs-acl.sh
./50-pbs-policies.sh
./60-pbs-gc-and-scrub.sh
./70-test.sh
```

## 🛡️ Bulletproof Features

### ✅ Comprehensive Validation
- **Environment detection**: Automatically detects if running on PBS/PVE node
- **Dependency checking**: Installs missing packages automatically
- **Connectivity tests**: Validates network connectivity before proceeding
- **Permission validation**: Ensures proper user privileges
- **Idempotent operations**: Safe to re-run multiple times

### ✅ Clear Error Messages
- **Emoji indicators**: ✅ Success, ❌ Error, ⚠️ Warning, 📦 Installing
- **Actionable feedback**: Tells you exactly what to fix
- **Context awareness**: Different behavior on PBS vs PVE nodes
- **Progress tracking**: Shows what's happening at each step

### ✅ Robust Error Handling
- **Early validation**: Catches issues before making changes
- **Graceful degradation**: Skips incompatible operations
- **Cleanup on failure**: Removes temporary files
- **Exit codes**: Proper error codes for scripting

### ✅ Security Best Practices
- **Token-based auth**: No hardcoded credentials
- **SSL fingerprint verification**: Prevents MITM attacks
- **Minimal permissions**: Only required access levels
- **Credential validation**: Checks auth before proceeding

## 📊 Testing & Validation

### Automatic Tests
All scripts include built-in validation:
- **99-validate-all.sh**: Comprehensive syntax and structure checks
- **05-preflight.sh**: Environment and connectivity validation
- **70-test.sh**: End-to-end functionality tests

### Manual Verification
```bash
# Check PBS storage on PVE node
pvesh get /storage | jq '.[] | select(.type=="pbs")'

# Check backup jobs
pvesh get /cluster/backup

# Check PBS policies (on PBS host)
proxmox-backup-manager prune-job list
proxmox-backup-manager verify-job list
```

## 🎛️ Configuration

### Core Settings (00-env.sh)
```bash
PBS_HOST="10.203.3.97"                    # PBS server IP/hostname
DATASTORES=("infra" "media" "test")        # Available datastores
PBS_USER="claude@pbs"                     # PBS authentication user
PBS_TOKEN_NAME="pbs-claude"               # API token name
ZPOOL_PREFERRED="zpbs"                     # ZFS pool for datastores
```

### Runtime Settings
```bash
export PBS_SECRET="your-token-secret"     # Required for PVE operations
```

## 🚨 Troubleshooting

### Common Issues & Solutions

#### "Not running on PVE/PBS node"
**Cause**: Script detects wrong environment
**Solution**: Run on correct node type, or use appropriate script variant

#### "PBS_SECRET not set"
**Cause**: Missing authentication token
**Solution**: `export PBS_SECRET="your-token-secret"`

#### "Cannot reach PBS host"
**Cause**: Network connectivity issues
**Solution**: Check firewall, DNS, and PBS service status

#### "Permission denied"
**Cause**: Insufficient privileges
**Solution**: Run as root user

#### "Storage already exists"
**Cause**: Previous configuration exists
**Solution**: This is normal - script will skip existing configurations

### Debug Mode
Run any script with debug output:
```bash
bash -x ./script-name.sh
```

## 🔄 Maintenance

### Regular Tasks
- **Weekly**: Review backup job status via PBS web UI
- **Monthly**: Check disk usage and retention policies
- **Quarterly**: Validate restore procedures
- **Yearly**: Review and update token expiration

### Monitoring
- **PBS Web UI**: https://your-pbs-host:8007
- **Netdata**: http://your-pve-node:19999 (if installed)
- **PVE Web UI**: https://your-pve-node:8006

## 🏆 Success Criteria

### For PVE Nodes
- ✅ PBS storage configurations created
- ✅ Backup jobs scheduled and running
- ✅ Test backup completes successfully
- ✅ No authentication errors in logs

### For PBS Servers
- ✅ Datastores created and accessible
- ✅ Prune/verify policies active
- ✅ GC and scrub jobs scheduled
- ✅ Client connections working

---

## 📞 Need Help?

Both repositories are designed to be self-documenting and fail-safe. If you encounter issues:

1. **Read the error message** - they're designed to be actionable
2. **Check the preflight** - `./05-preflight.sh` catches most issues
3. **Verify configuration** - Review `00-env.sh` settings
4. **Test connectivity** - Ensure PBS host is reachable
5. **Check logs** - PBS and PVE both log extensively

The goal is "copy, configure, run" - no surprises, no hidden gotchas! 🎯