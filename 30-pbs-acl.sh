#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

USE_TOKEN="${USE_TOKEN:-false}"
AUTH_ID="$PBS_USER"
if [[ "$USE_TOKEN" == "true" ]]; then
  AUTH_ID="${PBS_USER}!${PBS_TOKEN_NAME}"
fi

for DS in "${DATASTORES[@]}"; do
  # Try new ACL syntax first (role-based with --auth-id)
  if proxmox-backup-manager acl update "/datastore/${DS}" DatastoreAudit --auth-id "$AUTH_ID" 2>/dev/null && \
     proxmox-backup-manager acl update "/datastore/${DS}" DatastoreBackup --auth-id "$AUTH_ID" 2>/dev/null; then
    echo "Granted DatastoreAudit and DatastoreBackup on ${DS} to ${AUTH_ID} (new syntax)"
  else
    # Fallback to old syntax (subject with --privs)
    echo "New syntax failed, trying legacy --privs syntax..."
    proxmox-backup-manager acl update "/datastore/${DS}" "$AUTH_ID" --privs "Datastore.Backup,Datastore.Audit"
    echo "Granted Datastore.Backup,Datastore.Audit on ${DS} to ${AUTH_ID} (legacy syntax)"
  fi
done
