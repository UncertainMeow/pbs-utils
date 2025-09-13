# pbs-utils

Baseline PBS automation for host plato Prune and verify jobs on PBS GC and ZFS scrub cron Storage wiring and PVE backup job creation

## Quick start

### 1. On plato
```bash
./05-preflight.sh
./10-pbs-user-token.sh
./30-pbs-acl.sh
./50-pbs-policies.sh
./60-pbs-gc-and-scrub.sh
./70-test.sh
```

### 2. On each PVE node
```bash
# copy repo
scp -r plato:~/pbs-utils ~/pbs-utils
export PBS_SECRET='your-token-secret'
./40-pve-add-storage.sh

# optional backup jobs
./80-pve-jobs.sh --name nightly-infra --store pbs-infra --vm "101,102,103" --schedule "daily"

# or auto-discover VMs
./81-pve-discover-vms.sh --filter infra --store pbs-infra --schedule "daily"
```

## Notes

- If ping plato fails on a PVE node add a hosts entry:
  ```bash
  echo "10.203.3.97 plato" >> /etc/hosts
  ```
  or set PBS_HOST to the IP in 00-env.sh

- If you add more ZFS pools later set ZPOOL_PREFERRED once in 00-env.sh

## Scripts

- **00-env.sh** - Central configuration
- **05-preflight.sh** - Dependencies and environment checks  
- **10-pbs-user-token.sh** - Create PBS user and API token
- **30-pbs-acl.sh** - Grant datastore permissions
- **40-pve-add-storage.sh** - Add PBS storage to PVE nodes
- **50-pbs-policies.sh** - Create prune/verify jobs
- **60-pbs-gc-and-scrub.sh** - Install GC and ZFS scrub cron
- **70-test.sh** - Health checks and connectivity tests
- **80-pve-jobs.sh** - Create PVE backup jobs via CLI
- **81-pve-discover-vms.sh** - Auto-discover VMs and create backup jobs