#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

USE_TOKEN="${USE_TOKEN:-false}"
AUTH_ID="$PBS_USER"
if [[ "$USE_TOKEN" == "true" ]]; then
  AUTH_ID="${PBS_USER}!${PBS_TOKEN_NAME}"
fi

for DS in "${DATASTORES[@]}"; do
  # tokens do not accept --privs  you assign roles via ACLs
  proxmox-backup-manager acl update "/datastore/${DS}" DatastoreAudit  --auth-id "$AUTH_ID"
  proxmox-backup-manager acl update "/datastore/${DS}" DatastoreBackup --auth-id "$AUTH_ID"
  echo "Granted DatastoreAudit and DatastoreBackup on ${DS} to ${AUTH_ID}"
  # optional read rights
  # proxmox-backup-manager acl update "/datastore/${DS}" DatastoreReader --auth-id "$AUTH_ID"
done
