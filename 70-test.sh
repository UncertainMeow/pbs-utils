#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null | \
  openssl x509 -fingerprint -noout -sha256

proxmox-backup-client datastore list --repository "${PBS_HOST}:"

for DS in "${DATASTORES[@]}"; do
  proxmox-backup-manager verify run "verify-${DS}-daily" || true
done