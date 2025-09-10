# PBS-Utils - Proxmox Backup Server Automation

**Repository**: `pbs-utils`  
**Purpose**: Streamline Proxmox Backup Server (PBS) setup, configuration, and maintenance  
**Target Environment**: Homelab/enterprise Proxmox clusters with dedicated PBS host  

## Overview

This repository contains battle-tested scripts for automating PBS deployment and maintenance tasks. Born from the need to properly backup a "painstakingly perfect" Proxmox cluster, these tools eliminate manual configuration steps and ensure consistent, reliable backup infrastructure.

## Architecture

- **PBS Host**: `plato` (customizable in config)
- **Target**: Multiple PVE nodes backing up to centralized PBS
- **Storage**: ZFS-backed datastores with automated retention policies
- **Authentication**: API token-based auth with minimal privilege grants

## Scripts & Purpose

### Core Setup Scripts
- **`00-env.sh`** - Central configuration (datastores, schedules, hosts)
- **`05-preflight.sh`** - Dependency checks and environment validation
- **`10-pbs-user-token.sh`** - Create PBS user and API token
- **`30-pbs-acl.sh`** - Grant datastore permissions to backup user/token
- **`40-pve-add-storage.sh`** - Add PBS storage to PVE nodes
- **`50-pbs-policies.sh`** - Create prune/verify jobs on PBS
- **`60-pbs-gc-and-scrub.sh`** - Install GC and ZFS scrub cron jobs
- **`70-test.sh`** - Health checks and connectivity tests
- **`80-pve-jobs.sh`** - Create PVE backup jobs via CLI
- **`81-pve-discover-vms.sh`** - Auto-discover VMs and create backup jobs

### Key Features
- **Idempotent**: All scripts safe to re-run
- **Zero placeholders**: No `[CHANGE_THIS]` values to forget
- **Production-ready defaults**: 7-day/4-week/6-month/1-year retention
- **Multi-datastore support**: Separate policies for infra/media/test workloads
- **Comprehensive verification**: Weekly full + daily incremental verify jobs
- **Automated maintenance**: GC and ZFS scrub scheduling

## Quick Start

### On PBS Host (`plato`)
```bash
./05-preflight.sh
./10-pbs-user-token.sh     # Save token secret to 1Password
./30-pbs-acl.sh
./50-pbs-policies.sh
./60-pbs-gc-and-scrub.sh
./70-test.sh
```

### On Each PVE Node
```bash
scp -r plato:~/pbs-utils ~/pbs-utils
cd ~/pbs-utils
export PBS_SECRET='your-token-secret'
./40-pve-add-storage.sh
./80-pve-jobs.sh --name nightly-infra --store pbs-infra --vm "101,102,103" --schedule "daily"
```

## Configuration

### Datastores (`00-env.sh`)
```bash
DATASTORES=("infra" "media" "test")
```
- **infra**: Critical infrastructure VMs (tight retention)
- **media**: Media servers/storage (relaxed retention)  
- **test**: Development/testing (minimal retention)

### Schedules
- **Nightly backups**: 03:15 (customizable)
- **Weekly verify**: Saturday 04:30
- **GC runs**: Sunday 05:15
- **ZFS scrub**: Sunday 02:30

### Retention Policy (per datastore)
- Daily: 7 backups
- Weekly: 4 backups  
- Monthly: 6 backups
- Yearly: 1 backup

## Advanced Usage

### Custom VM Selection
```bash
# Backup specific VMs
./80-pve-jobs.sh --name critical-vms --store pbs-infra --vm "100,101,102" --schedule "02:00"

# Backup all VMs on a node
./80-pve-jobs.sh --name node1-all --store pbs-infra --all true --schedule "daily"

# Node-specific backups
./80-pve-jobs.sh --name pve1-infra --store pbs-infra --node pve1 --vm "100,101" --schedule "daily"
```

### Multiple ZFS Pools
```bash
# In 00-env.sh, set preferred pool name
ZPOOL_PREFERRED="pbs"
```

### Token vs User Authentication
```bash
# Grant ACL to user (default)
./30-pbs-acl.sh

# Grant ACL to token instead
USE_TOKEN=true ./30-pbs-acl.sh
```

## Security Model

### Authentication
- Dedicated PBS user (`pve-backup@pbs`) with minimal privileges
- API token authentication (no root access required)
- TLS certificate fingerprint validation

### Permissions
- **Datastore.Backup**: Create/manage backups
- **Datastore.Audit**: Read backup status/logs
- **No admin privileges**: Cannot modify PBS system settings

### Encryption
- Client-side encryption supported (optional)
- ZFS-level encryption available
- TLS for all PBS communications

## Monitoring & Maintenance

### Automated Tasks
- **Pruning**: Daily cleanup per retention policy
- **Verification**: Weekly full + daily spot checks
- **Garbage Collection**: Weekly reclaim of unused chunks
- **ZFS Scrub**: Weekly integrity checks

### Health Monitoring
```bash
# Check backup status
./70-test.sh

# Manual verify run  
proxmox-backup-manager verify run verify-infra-daily

# Check GC status
proxmox-backup-manager garbage-collection status infra
```

### Alerting
- Email notifications via PBS SMTP configuration
- Syslog integration for backup job results
- Custom notification endpoints (Gotify, webhooks)

## Troubleshooting

### Common Issues
1. **DNS Resolution**: Add PBS host to `/etc/hosts` if ping fails
2. **Dependencies**: Run `apt install jq openssl` on PVE nodes
3. **Token Secrets**: Store in 1Password, export before running scripts
4. **Multiple ZFS Pools**: Set `ZPOOL_PREFERRED` in config

### Recovery Operations
```bash
# Remove PVE storage
pvesh delete /storage/pbs-infra

# Delete PBS jobs
proxmox-backup-manager prune-job remove keep-infra
proxmox-backup-manager verify-job remove verify-infra-weekly

# Remove token
proxmox-backup-manager user delete-token pve-backup@pbs pve-token
```

## Best Practices

### Infrastructure
- Dedicated PBS host (not on PVE nodes)
- ZFS storage pool with appropriate redundancy
- Network separation for backup traffic
- Regular PBS system updates

### Backup Strategy  
- Start with critical VMs only
- Test restore procedures regularly
- Monitor backup sizes and growth trends
- Document recovery procedures

### Maintenance
- Review retention policies quarterly
- Monitor PBS disk usage trends  
- Test email notifications
- Validate backup integrity via verification jobs

## Evolution & Customization

This repository is designed to grow with your infrastructure:

- **Add datastores**: Modify `DATASTORES` array in `00-env.sh`
- **Custom schedules**: Update timing variables for your maintenance windows
- **Additional PVE nodes**: Run `40-pve-add-storage.sh` on new nodes
- **VM discovery**: Use `81-pve-discover-vms.sh` for automated job creation

The goal is to have a "set it and forget it" backup infrastructure that you can trust with your painstakingly perfect cluster.

## Contributing

When modifying scripts:
1. Maintain idempotent behavior
2. Add error handling for common failure modes
3. Update this documentation
4. Test in a lab environment first

---

*"The best backup is the one that runs automatically and restores successfully."*