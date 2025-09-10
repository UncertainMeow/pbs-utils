#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# requires PBS_SECRET env var containing the token secret
if [[ -z "${PBS_SECRET:-}" ]]; then
  echo "Export PBS_SECRET with your token secret then re-run"
  exit 1
fi

TOKEN_ID="${PBS_USER}!${PBS_TOKEN_NAME}"
FPRINT=$(openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null | \
  openssl x509 -fingerprint -noout -sha256 | cut -d'=' -f2)

# add one storage per datastore named pbs-<datastore>
for DS in "${DATASTORES[@]}"; do
  NAME="pbs-${DS}"
  if pvesh get /storage 2>/dev/null | jq -r '.[].storage' | grep -qx "$NAME"; then
    echo "Storage $NAME already exists  skipping"
    continue
  fi

  pvesh create /storage --storage "$NAME" --type pbs \
    --server "$PBS_HOST" \
    --datastore "$DS" \
    --username "$TOKEN_ID" \
    --password "$PBS_SECRET" \
    --fingerprint "$FPRINT" \
    --content "backup"

  echo "Added storage $NAME -> ${PBS_HOST}:${DS}"
done