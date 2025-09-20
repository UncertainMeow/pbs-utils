#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# In PBS 4.0+, tokens need their own permissions separate from users
# Grant permissions to BOTH user AND token for maximum compatibility

for DS in "${DATASTORES[@]}"; do
  echo "🔐 Configuring permissions for datastore: ${DS}"

  # Grant permissions to USER
  if proxmox-backup-manager acl update "/datastore/${DS}" DatastoreAudit --auth-id "$PBS_USER" 2>/dev/null && \
     proxmox-backup-manager acl update "/datastore/${DS}" DatastoreBackup --auth-id "$PBS_USER" 2>/dev/null; then
    echo "✅ Granted DatastoreAudit and DatastoreBackup on ${DS} to ${PBS_USER}"
  else
    echo "⚠️  Failed to grant permissions to user ${PBS_USER}"
  fi

  # Grant permissions to TOKEN (PBS 4.0+ requirement)
  TOKEN_ID="${PBS_USER}!${PBS_TOKEN_NAME}"
  if proxmox-backup-manager acl update "/datastore/${DS}" DatastoreAudit --auth-id "$TOKEN_ID" 2>/dev/null && \
     proxmox-backup-manager acl update "/datastore/${DS}" DatastoreBackup --auth-id "$TOKEN_ID" 2>/dev/null; then
    echo "✅ Granted DatastoreAudit and DatastoreBackup on ${DS} to ${TOKEN_ID}"
  else
    echo "⚠️  Failed to grant permissions to token ${TOKEN_ID} (may need to be created first)"
  fi
done

echo ""
echo "🎯 ACL Configuration Summary:"
echo "   User permissions: ${PBS_USER}"
echo "   Token permissions: ${PBS_USER}!${PBS_TOKEN_NAME}"
echo "   Datastores: ${DATASTORES[*]}"
