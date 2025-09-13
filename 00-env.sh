#!/usr/bin/env bash
set -euo pipefail

# PBS Host - can be hostname or IP address
# If hostname: scripts validate they're running on that host
# If IP address: scripts validate that IP exists on this host
PBS_HOST="plato"

# datastores to manage
DATASTORES=("infra" "media" "test")

# backup windows
NIGHTLY="03:15"
WEEKLY="Sat 04:30"
GCWEEKLY="Sun 05:15"

# backup user and token on PBS
PBS_USER="pve-backup@pbs"
PBS_TOKEN_NAME="pve-token"     # token id is pve-backup@pbs!pve-token

# ZFS pool detection on PBS
# set this once later if you add more pools
ZPOOL_PREFERRED="zpbs"
ZPOOL_PREFERRED="${ZPOOL_PREFERRED:-}"
ZPOOL="${ZPOOL:-}"

if [[ -n "$ZPOOL_PREFERRED" ]]; then
  if zpool list -H -o name | grep -qx "$ZPOOL_PREFERRED"; then
    ZPOOL="$ZPOOL_PREFERRED"
  else
    echo "Preferred pool '$ZPOOL_PREFERRED' not found. Pools available:"
    zpool list -H -o name
    exit 1
  fi
fi

if [[ -z "$ZPOOL" ]]; then
  POOLS=$(zpool list -H -o name | awk 'NF')
  COUNT=$(echo "$POOLS" | wc -l | tr -d ' ')
  if [[ "$COUNT" -eq 1 ]]; then
    ZPOOL="$POOLS"
  else
    echo "Multiple pools found. Set ZPOOL_PREFERRED or ZPOOL in 00-env.sh then re-run."
    echo "$POOLS"
    exit 1
  fi
fi
