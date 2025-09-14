#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null | \
  openssl x509 -fingerprint -noout -sha256

# Test PBS connectivity and datastore availability
proxmox-backup-manager node show
proxmox-backup-manager datastore list

for DS in "${DATASTORES[@]}"; do
  echo "Running verification test for datastore: $DS"
  proxmox-backup-manager verify-job run "verify-${DS}-daily" || echo "  No backups to verify yet for $DS"
done