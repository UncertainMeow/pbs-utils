# Manual PBS Setup Guide

## On PBS Host (10.203.3.97) - Run these commands directly

### 1. Create the pbs-utils directory and key files

```bash
mkdir -p ~/pbs-utils
cd ~/pbs-utils
```

### 2. Create 00-env.sh
```bash
cat > 00-env.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

# PBS Host - can be hostname or IP address
# If hostname: scripts validate they're running on that host
# If IP address: scripts validate that IP exists on this host
PBS_HOST="10.203.3.97"

# datastores to manage
DATASTORES=("infra" "media" "test")

# backup windows
NIGHTLY="03:15"
WEEKLY="Sat 04:30"
GCWEEKLY="Sun 05:15"

# backup user and token on PBS
PBS_USER="pve-backup@pbs"
PBS_TOKEN_NAME="pve-token"     # token id is pve-backup@pbs!pve-token

# ZFS pool detection on PBS (only run if zpool command exists)
# set this once later if you add more pools
ZPOOL_PREFERRED="zpbs"
ZPOOL_PREFERRED="${ZPOOL_PREFERRED:-}"
ZPOOL="${ZPOOL:-}"

# Only do ZFS pool detection if we can determine we're on PBS host
# Don't fail on PVE nodes that don't have ZFS
if command -v zpool >/dev/null 2>&1; then
  # Check if we're on the PBS host (either by hostname or IP)
  ON_PBS_HOST=false
  if [[ "$PBS_HOST" == "$(hostname)" ]] || [[ "$PBS_HOST" == "$(hostname -f)" ]]; then
    ON_PBS_HOST=true
  elif command -v ip >/dev/null 2>&1 && ip addr show | grep -q "$PBS_HOST"; then
    ON_PBS_HOST=true
  fi

  if [[ -n "$ZPOOL_PREFERRED" ]]; then
    if zpool list -H -o name | grep -qx "$ZPOOL_PREFERRED"; then
      ZPOOL="$ZPOOL_PREFERRED"
    elif [[ "$ON_PBS_HOST" == "true" ]]; then
      echo "❌ Preferred pool '$ZPOOL_PREFERRED' not found on PBS host. Pools available:"
      zpool list -H -o name
      exit 1
    fi
  fi

  if [[ -z "$ZPOOL" ]]; then
    POOLS=$(zpool list -H -o name | awk 'NF' 2>/dev/null || echo "")
    if [[ -n "$POOLS" ]]; then
      COUNT=$(echo "$POOLS" | wc -l | tr -d ' ')
      if [[ "$COUNT" -eq 1 ]]; then
        ZPOOL="$POOLS"
      elif [[ "$ON_PBS_HOST" == "true" ]]; then
        echo "❌ Multiple pools found on PBS host. Set ZPOOL_PREFERRED or ZPOOL in 00-env.sh then re-run."
        echo "$POOLS"
        exit 1
      fi
    fi
  fi
fi
EOF
chmod +x 00-env.sh
```

### 3. Create 10-pbs-user-token.sh
```bash
cat > 10-pbs-user-token.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

source ./00-env.sh

echo "🔐 Creating PBS backup user and token..."
echo "=================================="

# Create user if it doesn't exist
if ! proxmox-backup-manager user list | grep -q "^${PBS_USER}"; then
    echo "👤 Creating user: ${PBS_USER}"
    proxmox-backup-manager user create "${PBS_USER}" --comment "Automated backup user"
else
    echo "✅ User ${PBS_USER} already exists"
fi

# Create token
echo "🔑 Creating API token: ${PBS_TOKEN_NAME}"
if proxmox-backup-manager user list-tokens "${PBS_USER}" 2>/dev/null | grep -q "${PBS_TOKEN_NAME}"; then
    echo "⚠️  Token ${PBS_TOKEN_NAME} already exists - will show existing secret"
    # Get existing token info
    proxmox-backup-manager user list-tokens "${PBS_USER}"
else
    # Create new token and capture the secret
    echo "Creating new token..."
    TOKEN_OUTPUT=$(proxmox-backup-manager user generate-token "${PBS_USER}" "${PBS_TOKEN_NAME}" 2>&1)
    echo "$TOKEN_OUTPUT"
fi

echo ""
echo "🎯 Important: Save this token secret to your password manager!"
echo "   You'll need it when configuring PVE nodes"
echo "   Export it as: export PBS_SECRET='your-token-secret-here'"
echo ""
echo "✅ PBS user and token setup complete"
EOF
chmod +x 10-pbs-user-token.sh
```

### 4. Create 30-pbs-acl.sh
```bash
cat > 30-pbs-acl.sh << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

source ./00-env.sh

echo "🔐 Setting up PBS ACL permissions..."
echo "=================================="

# Grant permissions for each datastore
for ds in "${DATASTORES[@]}"; do
    echo "🔐 Configuring permissions for datastore: $ds"

    # Grant to user
    if proxmox-backup-manager acl update "/datastore/$ds" "${PBS_USER}" --role DatastoreBackup; then
        echo "✅ Granted DatastoreBackup to user ${PBS_USER} on $ds"
    else
        echo "⚠️  Failed to grant permissions to user ${PBS_USER}"
    fi

    # Grant to token
    if proxmox-backup-manager acl update "/datastore/$ds" "${PBS_USER}!${PBS_TOKEN_NAME}" --role DatastoreBackup; then
        echo "✅ Granted DatastoreBackup to token ${PBS_USER}!${PBS_TOKEN_NAME} on $ds"
    else
        echo "⚠️  Failed to grant permissions to token ${PBS_USER}!${PBS_TOKEN_NAME} (may need to be created first)"
    fi
done

echo ""
echo "🎯 ACL Configuration Summary:"
echo "   User permissions: ${PBS_USER}"
echo "   Token permissions: ${PBS_USER}!${PBS_TOKEN_NAME}"
echo "   Datastores: ${DATASTORES[*]}"
EOF
chmod +x 30-pbs-acl.sh
```

### 5. Run the PBS setup sequence

```bash
# 1. Create user and token (SAVE THE SECRET!)
./10-pbs-user-token.sh

# 2. Set up permissions
./30-pbs-acl.sh

# 3. Verify setup
proxmox-backup-manager user list
proxmox-backup-manager user list-tokens pve-backup@pbs
proxmox-backup-manager acl list
```

### 6. Test from PVE node

Once PBS setup is complete, test from rawls:

```bash
# On rawls (10.203.3.47)
cd ~/pbs-utils
export PBS_SECRET="your-token-secret-from-step-5"
./40-pve-add-storage.sh
```

---

## Quick Fix for Existing Token

The token `6868ee30-ca08-4547-90c7-6f58bc862228` needs proper permissions. Run these commands on PBS host:

```bash
# Check if user/token exists
proxmox-backup-manager user list
proxmox-backup-manager user list-tokens pve-backup@pam 2>/dev/null || echo "User doesn't exist"

# Create user if needed (might already exist)
proxmox-backup-manager user create "pve-backup@pam" --comment "Automated backup user" 2>/dev/null || echo "User already exists"

# Check datastores exist
proxmox-backup-manager datastore list

# Set ACL permissions for existing token
proxmox-backup-manager acl update "/datastore/infra" "pve-backup@pam!pve-token" --role DatastoreBackup
proxmox-backup-manager acl update "/datastore/media" "pve-backup@pam!pve-token" --role DatastoreBackup
proxmox-backup-manager acl update "/datastore/test" "pve-backup@pam!pve-token" --role DatastoreBackup

# Verify ACL is set
proxmox-backup-manager acl list | grep pve-backup
```

If datastores don't exist, create them:
```bash
# Create datastores (adjust paths as needed)
proxmox-backup-manager datastore create infra /zpbs/infra
proxmox-backup-manager datastore create media /zpbs/media
proxmox-backup-manager datastore create test /zpbs/test
```

Then test on rawls:
```bash
export PBS_SECRET="6868ee30-ca08-4547-90c7-6f58bc862228"
./40-pve-add-storage.sh
```