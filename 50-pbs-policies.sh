#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

for DS in "${DATASTORES[@]}"; do
  JOB="keep-${DS}"
  if ! proxmox-backup-manager prune-job list | awk '{print $1}' | grep -qx "$JOB"; then
    proxmox-backup-manager prune-job create "$JOB" \
      --store "$DS" \
      --schedule "daily" \
      --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1
    echo "Created prune job $JOB on $DS"
  else
    echo "Prune job $JOB exists"
  fi

  VJ="verify-${DS}-weekly"
  if ! proxmox-backup-manager verify-job list | awk '{print $1}' | grep -qx "$VJ"; then
    proxmox-backup-manager verify-job create "$VJ" \
      --store "$DS" \
      --schedule "$WEEKLY" \
      --outdated-only true
    echo "Created verify job $VJ on $DS"
  else
    echo "Verify job $VJ exists"
  fi

  VD="verify-${DS}-daily"
  if ! proxmox-backup-manager verify-job list | awk '{print $1}' | grep -qx "$VD"; then
    proxmox-backup-manager verify-job create "$VD" \
      --store "$DS" \
      --schedule "$NIGHTLY" \
      --max-worker 1 \
      --outdated-only true
    echo "Created verify job $VD on $DS"
  else
    echo "Verify job $VD exists"
  fi
done