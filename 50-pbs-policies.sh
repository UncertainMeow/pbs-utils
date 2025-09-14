#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

for DS in "${DATASTORES[@]}"; do
  JOB="keep-${DS}"
  
  # Check if prune job exists with more robust method
  if proxmox-backup-manager prune-job show "$JOB" >/dev/null 2>&1; then
    echo "Prune job $JOB already exists - skipping creation"
  else
    echo "Creating prune job $JOB on $DS..."
    if proxmox-backup-manager prune-job create "$JOB" \
      --store "$DS" \
      --schedule "daily" \
      --keep-daily 7 --keep-weekly 4 --keep-monthly 6 --keep-yearly 1; then
      echo "✅ Created prune job $JOB on $DS"
    else
      echo "⚠️  Failed to create prune job $JOB (may already exist)"
    fi
  fi

  VJ="verify-${DS}-weekly"
  # Check if weekly verify job exists
  if proxmox-backup-manager verify-job show "$VJ" >/dev/null 2>&1; then
    echo "Weekly verify job $VJ already exists - skipping creation"
  else
    echo "Creating weekly verify job $VJ on $DS..."
    if proxmox-backup-manager verify-job create "$VJ" \
      --store "$DS" \
      --schedule "$WEEKLY" \
      --ignore-verified true; then
      echo "✅ Created weekly verify job $VJ on $DS"
    else
      echo "⚠️  Failed to create weekly verify job $VJ (may already exist)"
    fi
  fi

  VD="verify-${DS}-daily"
  # Check if daily verify job exists
  if proxmox-backup-manager verify-job show "$VD" >/dev/null 2>&1; then
    echo "Daily verify job $VD already exists - skipping creation"
  else
    echo "Creating daily verify job $VD on $DS..."
    if proxmox-backup-manager verify-job create "$VD" \
      --store "$DS" \
      --schedule "$NIGHTLY" \
      --ignore-verified true; then
      echo "✅ Created daily verify job $VD on $DS"
    else
      echo "⚠️  Failed to create daily verify job $VD (may already exist)"
    fi
  fi
done