#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# usage
# ./80-pve-jobs.sh --name nightly-infra --store pbs-infra --vm "101,102,103" --schedule "daily" --mode snapshot
# ./80-pve-jobs.sh --name weekly-all --store pbs-infra --all true --schedule "Sat 03:30" --mode snapshot
# optional
#   --node pve1
#   --mailto you@example.com
#   --compress zstd

NAME=""
STORE=""
VMIDS=""
ALL="false"
SCHEDULE="daily"
MODE="snapshot"
NODE=""
MAILTO=""
COMPRESS="zstd"

while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --name) NAME="$2"; shift 2;;
    --store) STORE="$2"; shift 2;;
    --vm) VMIDS="$2"; shift 2;;
    --all) ALL="$2"; shift 2;;
    --schedule) SCHEDULE="$2"; shift 2;;
    --mode) MODE="$2"; shift 2;;
    --node) NODE="$2"; shift 2;;
    --mailto) MAILTO="$2"; shift 2;;
    --compress) COMPRESS="$2"; shift 2;;
    *) echo "Unknown arg $1"; exit 1;;
  esac
done

if [[ -z "$NAME" || -z "$STORE" ]]; then
  echo "Need --name and --store"
  exit 1
fi

if ! pvesh get /storage 2>/dev/null | jq -r '.[].storage' | grep -qx "$STORE"; then
  echo "Storage $STORE not found on this node  run 40-pve-add-storage.sh first"
  exit 1
fi

ARGS=(/cluster/backup)
ARGS+=(-create)
ARGS+=(--storage "$STORE")
ARGS+=(--mode "$MODE")
ARGS+=(--schedule "$SCHEDULE")
ARGS+=(--compress "$COMPRESS")
ARGS+=(--enabled 1)
ARGS+=(--comment "$NAME")

if [[ -n "$MAILTO" ]]; then ARGS+=(--mailto "$MAILTO"); fi
if [[ -n "$NODE" ]]; then ARGS+=(--nodes "$NODE"); fi

if [[ "$ALL" == "true" ]]; then
  ARGS+=(--all 1)
elif [[ -n "$VMIDS" ]]; then
  ARGS+=(--vmid "$VMIDS")
else
  echo "Specify either --all true or --vm 'id1,id2'"
  exit 1
fi

pvesh create "${ARGS[@]}"
echo "Created backup job '$NAME' targeting $STORE schedule '$SCHEDULE' mode '$MODE'"