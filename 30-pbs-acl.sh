#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

USE_TOKEN="${USE_TOKEN:-false}"
SUBJECT="$PBS_USER"
if [[ "$USE_TOKEN" == "true" ]]; then
  SUBJECT="${PBS_USER}!${PBS_TOKEN_NAME}"
fi

for DS in "${DATASTORES[@]}"; do
  proxmox-backup-manager acl update "/datastore/${DS}" "$SUBJECT" --privs "Datastore.Backup,Datastore.Audit"
  echo "Granted Datastore.Backup,Datastore.Audit on ${DS} to ${SUBJECT}"
done