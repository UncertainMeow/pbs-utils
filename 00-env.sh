#!/usr/bin/env bash
set -euo pipefail

# PBS Host - can be hostname or IP address
# If hostname: scripts validate they're running on that host
# If IP address: scripts validate that IP exists on this host
PBS_HOST="10.203.3.97"

# datastores to manage
DATASTORES=("infra" "media" "test")

# backup windows
NIGHTLY="03:15"
WEEKLY="Sat 04:30"
GCWEEKLY="Sun 05:15"

# backup user and token on PBS
PBS_USER="pve-backup@pbs"
PBS_TOKEN_NAME="pve-token"     # token id is pve-backup@pbs!pve-token

# ZFS pool detection on PBS (only run if zpool command exists)
# set this once later if you add more pools
ZPOOL_PREFERRED="zpbs"
ZPOOL_PREFERRED="${ZPOOL_PREFERRED:-}"
ZPOOL="${ZPOOL:-}"

# Only do ZFS pool detection if we can determine we're on PBS host
# Don't fail on PVE nodes that don't have ZFS
if command -v zpool >/dev/null 2>&1; then
  # Check if we're on the PBS host (either by hostname or IP)
  ON_PBS_HOST=false
  if [[ "$PBS_HOST" == "$(hostname)" ]] || [[ "$PBS_HOST" == "$(hostname -f)" ]]; then
    ON_PBS_HOST=true
  elif command -v ip >/dev/null 2>&1 && ip addr show | grep -q "$PBS_HOST"; then
    ON_PBS_HOST=true
  fi

  if [[ -n "$ZPOOL_PREFERRED" ]]; then
    if zpool list -H -o name | grep -qx "$ZPOOL_PREFERRED"; then
      ZPOOL="$ZPOOL_PREFERRED"
    elif [[ "$ON_PBS_HOST" == "true" ]]; then
      echo "❌ Preferred pool '$ZPOOL_PREFERRED' not found on PBS host. Pools available:"
      zpool list -H -o name
      exit 1
    fi
  fi

  if [[ -z "$ZPOOL" ]]; then
    POOLS=$(zpool list -H -o name | awk 'NF' 2>/dev/null || echo "")
    if [[ -n "$POOLS" ]]; then
      COUNT=$(echo "$POOLS" | wc -l | tr -d ' ')
      if [[ "$COUNT" -eq 1 ]]; then
        ZPOOL="$POOLS"
      elif [[ "$ON_PBS_HOST" == "true" ]]; then
        echo "❌ Multiple pools found on PBS host. Set ZPOOL_PREFERRED or ZPOOL in 00-env.sh then re-run."
        echo "$POOLS"
        exit 1
      fi
    fi
  fi
fi
