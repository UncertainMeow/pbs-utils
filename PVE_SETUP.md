# PVE Node Setup Instructions

## Quick Setup for Each PVE Node

### 1. Copy Scripts to PVE Node
```bash
scp -r /Users/kellen/_code/UncertainMeow/pbs-utils root@<PVE_NODE_IP>:~/pbs-utils
```

### 2. On Each PVE Node, Run:
```bash
cd ~/pbs-utils
export PBS_SECRET="6868ee30-ca08-4547-90c7-6f58bc862228"
./40-pve-add-storage.sh
```

### 3. Verify Storage Added
```bash
pvesh get /storage | jq -r '.[].storage' | grep pbs-
```

Should show:
- pbs-infra
- pbs-media
- pbs-test

### 4. Create Backup Jobs
```bash
# Example: backup VMs 100,101,102 to infra datastore nightly
./80-pve-jobs.sh --name nightly-infra --store pbs-infra --vm "100,101,102" --schedule "daily"

# Or auto-discover and backup all VMs
./81-pve-discover-vms.sh
```

## Manual Commands (if scripts fail)

### Add PBS Storage Manually
```bash
TOKEN_ID="claude@pbs!pbs-claude"
PBS_SECRET="6868ee30-ca08-4547-90c7-6f58bc862228"
FPRINT="93:FD:C1:CB:9F:1B:87:35:A2:DA:94:52:FD:9D:26:C4:A4:81:C0:FB:31:D3:99:B9:9A:A9:A1:9F:9F:B0:74:C2"

# Add infra storage
pvesh create /storage --storage "pbs-infra" --type pbs \
  --server "10.203.3.97" --datastore "infra" \
  --username "$TOKEN_ID" --password "$PBS_SECRET" \
  --fingerprint "$FPRINT" --content "backup"

# Add media storage
pvesh create /storage --storage "pbs-media" --type pbs \
  --server "10.203.3.97" --datastore "media" \
  --username "$TOKEN_ID" --password "$PBS_SECRET" \
  --fingerprint "$FPRINT" --content "backup"

# Add test storage
pvesh create /storage --storage "pbs-test" --type pbs \
  --server "10.203.3.97" --datastore "test" \
  --username "$TOKEN_ID" --password "$PBS_SECRET" \
  --fingerprint "$FPRINT" --content "backup"
```

### Create Backup Job Manually
```bash
# Create nightly backup job for VMs 100,101,102
pvesh create /cluster/backup --starttime "03:15" --dow "mon,tue,wed,thu,fri,sat,sun" \
  --storage "pbs-infra" --vmid "100,101,102" --enabled 1 \
  --comment "Automated infra backup"
```

## Troubleshooting

### If SSL fingerprint doesn't match:
```bash
openssl s_client -connect "10.203.3.97:8007" -showcerts </dev/null 2>/dev/null | \
  openssl x509 -fingerprint -noout -sha256
```

### If PBS datastores don't exist:
The claude@pbs token may not have permission to create datastores. Log into PBS web UI at https://10.203.3.97:8007 and manually create:
- infra (path: /zpbs/infra)
- media (path: /zpbs/media)
- test (path: /zpbs/test)

### Test connectivity from PVE node:
```bash
curl -k https://10.203.3.97:8007/api2/json/version
ping 10.203.3.97
```