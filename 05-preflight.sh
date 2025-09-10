#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo "Checking dependencies on PBS host ${PBS_HOST}"
which proxmox-backup-manager proxmox-backup-client openssl >/dev/null || {
  echo "Missing deps. Run on plato:"
  echo "  apt update && apt install -y proxmox-backup-server openssl"
  exit 1
}

echo "ZFS pool selected: ${ZPOOL}"
zpool list -o name,size,free

echo "TLS fingerprint for ${PBS_HOST}"
openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null | \
  openssl x509 -fingerprint -noout -sha256