#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Validate we're running on the correct PBS host
HOSTNAME_NOW=$(hostname -s)
if [[ "$PBS_HOST" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  # PBS_HOST is an IP address - check if we can reach it locally
  if ! ip addr show | grep -q "$PBS_HOST"; then
    echo "PBS_HOST is set to IP $PBS_HOST but this host doesn't have that IP"
    echo "Current host: $HOSTNAME_NOW"
    echo "If this is the correct PBS host, make sure PBS_HOST is set correctly in 00-env.sh"
    exit 1
  fi
else
  # PBS_HOST is a hostname - check if we're on that host
  if [[ "$HOSTNAME_NOW" != "$PBS_HOST" ]]; then
    echo "Run this on PBS host ${PBS_HOST}. Current host is ${HOSTNAME_NOW}"
    exit 1
  fi
fi

TMPCRON="$(mktemp)"
crontab -l 2>/dev/null | sed '/proxmox-backup-manager garbage-collection/d' | sed '/zpool scrub/d' > "$TMPCRON" || true

dow_num () {
  case "$1" in
    Sun) echo 0 ;;
    Mon) echo 1 ;;
    Tue) echo 2 ;;
    Wed) echo 3 ;;
    Thu) echo 4 ;;
    Fri) echo 5 ;;
    Sat) echo 6 ;;
    *) echo "bad" ;;
  esac
}

DOW=$(echo "$GCWEEKLY" | awk '{print $1}')
HM=$(echo "$GCWEEKLY" | awk '{print $2}')
MIN=$(echo "$HM" | cut -d: -f2)
HOUR=$(echo "$HM" | cut -d: -f1)
DOW_NUM=$(dow_num "$DOW")
if [[ "$DOW_NUM" == "bad" ]]; then
  echo "Bad GCWEEKLY format  use like 'Sun 05:15'"
  exit 1
fi

for DS in "${DATASTORES[@]}"; do
  echo "${MIN} ${HOUR} * * ${DOW_NUM} root proxmox-backup-manager garbage-collection start ${DS}" >> "$TMPCRON"
done

# weekly scrub on ZPOOL Sunday 02:30
echo "30 2 * * 0 root zpool scrub ${ZPOOL}" >> "$TMPCRON"

crontab "$TMPCRON"
rm -f "$TMPCRON"

echo "Installed cron for GC and zpool scrub  check with crontab -l"