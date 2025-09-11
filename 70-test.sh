#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null | \
  openssl x509 -fingerprint -noout -sha256

# Test PBS connectivity and datastore availability
proxmox-backup-manager status
proxmox-backup-manager datastore list

for DS in "${DATASTORES[@]}"; do
  proxmox-backup-manager verify run "verify-${DS}-daily" || true
done