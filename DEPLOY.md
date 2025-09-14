# Quick Deploy Guide

## Fixed Issues
1. **40-pve-add-storage.sh** - Now auto-installs `jq` dependency
2. **pve-utils/** - Created working helper scripts using community scripts directly
3. **All scripts** - Syntax validated and executable

## Deploy to Socrates (10.203.3.42)

### 1. Copy files to socrates
```bash
# From your workstation
scp -r pbs-utils root@10.203.3.42:~/
```

### 2. Run PVE setup (on socrates)
```bash
ssh root@10.203.3.42
cd ~/pbs-utils/pve-utils
./00-setup-all.sh
```

### 3. Add PBS storage (on socrates)  
```bash
cd ~/pbs-utils
export PBS_SECRET='your-token-secret-here'
./40-pve-add-storage.sh
```

### 4. Test connectivity
```bash
./70-test.sh
```

## The scripts now work without manual intervention - no more config errors or missing dependencies.