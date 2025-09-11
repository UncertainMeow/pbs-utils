#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

HOSTNAME_NOW=$(hostname -s)
if [[ "$HOSTNAME_NOW" != "$PBS_HOST" ]]; then
  echo "Run this on PBS host ${PBS_HOST}. Current host is ${HOSTNAME_NOW}"
  exit 1
fi

# create user if missing
if ! proxmox-backup-manager user list | awk '{print $1}' | grep -qx "$PBS_USER"; then
  proxmox-backup-manager user create "$PBS_USER"
  echo "Created PBS user $PBS_USER"
fi

# create token if missing
TOKEN_ID="${PBS_USER}!${PBS_TOKEN_NAME}"
if ! proxmox-backup-manager user list-tokens "$PBS_USER" | awk '{print $1}' | grep -qx "$TOKEN_ID"; then
  # generate token  capture secret
  # Try without --privs first (newer PBS versions)
  if ! proxmox-backup-manager user generate-token "$PBS_USER" "$PBS_TOKEN_NAME" \
    | tee .pbs_token_create.out 2>/dev/null; then
    # Fallback to old syntax with --privs (older PBS versions)
    echo "Token creation failed, trying legacy --privs syntax..."
    proxmox-backup-manager user generate-token "$PBS_USER" "$PBS_TOKEN_NAME" \
      --privs "Datastore.Backup Datastore.Audit" | tee .pbs_token_create.out
  fi
  echo "Saved token output to .pbs_token_create.out  store secret in 1Password"
else
  echo "Token $TOKEN_ID already exists  if you need the secret delete and recreate"
fi

# TLS fingerprint for convenience
openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null \
  | openssl x509 -fingerprint -noout -sha256 | tee .pbs_tls_fingerprint.out

echo "Next  ./30-pbs-acl.sh then ./50-pbs-policies.sh then ./60-pbs-gc-and-scrub.sh"
