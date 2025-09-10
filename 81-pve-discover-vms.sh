#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# usage
# ./81-pve-discover-vms.sh --filter infra --store pbs-infra --schedule "daily"
# ./81-pve-discover-vms.sh --node pve1 --store pbs-infra --schedule "daily"
# ./81-pve-discover-vms.sh --all --store pbs-infra --schedule "daily"

FILTER=""
NODE=""
ALL="false"
STORE=""
SCHEDULE="daily"
MODE="snapshot"

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --filter) FILTER="$2"; shift 2;;
    --node) NODE="$2"; shift 2;;
    --all) ALL="true"; shift;;
    --store) STORE="$2"; shift 2;;
    --schedule) SCHEDULE="$2"; shift 2;;
    --mode) MODE="$2"; shift 2;;
    *) echo "Unknown arg $1"; exit 1;;
  esac
done

if [[ -z "$STORE" ]]; then
  echo "Need --store"
  exit 1
fi

# Get all VMs/CTs from the cluster
if [[ "$ALL" == "true" ]]; then
  VMIDS=$(pvesh get /cluster/resources --type vm | jq -r '.[].vmid' | sort -n | tr '\n' ',' | sed 's/,$//')
  JOB_NAME="auto-all"
elif [[ -n "$NODE" ]]; then
  VMIDS=$(pvesh get /nodes/"$NODE"/qemu | jq -r '.[].vmid' | sort -n | tr '\n' ',' | sed 's/,$//')
  CT_IDS=$(pvesh get /nodes/"$NODE"/lxc | jq -r '.[].vmid' | sort -n | tr '\n' ',' | sed 's/,$//')
  if [[ -n "$VMIDS" && -n "$CT_IDS" ]]; then
    VMIDS="${VMIDS},${CT_IDS}"
  elif [[ -n "$CT_IDS" ]]; then
    VMIDS="$CT_IDS"
  fi
  JOB_NAME="auto-${NODE}"
elif [[ -n "$FILTER" ]]; then
  # Find VMs with name containing filter string
  VM_LIST=$(pvesh get /cluster/resources --type vm | jq -r '.[] | select(.name | contains("'$FILTER'")) | .vmid' | sort -n)
  if [[ -z "$VM_LIST" ]]; then
    echo "No VMs found with name containing '$FILTER'"
    exit 1
  fi
  VMIDS=$(echo "$VM_LIST" | tr '\n' ',' | sed 's/,$//')
  JOB_NAME="auto-${FILTER}"
else
  echo "Specify --all, --node <name>, or --filter <string>"
  exit 1
fi

if [[ -z "$VMIDS" ]]; then
  echo "No VMs found to backup"
  exit 1
fi

echo "Discovered VM/CT IDs: $VMIDS"
echo "Creating backup job '$JOB_NAME' for these VMs..."

# Use the existing 80-pve-jobs.sh script to create the job
"$(dirname "$0")/80-pve-jobs.sh" --name "$JOB_NAME" --store "$STORE" --vm "$VMIDS" --schedule "$SCHEDULE" --mode "$MODE"

echo "Created auto-discovered backup job '$JOB_NAME'"