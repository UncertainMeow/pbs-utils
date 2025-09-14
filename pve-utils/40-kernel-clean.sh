#!/usr/bin/env bash
set -euo pipefail

echo "Running kernel cleanup script..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/kernel-clean.sh)"
echo "Kernel cleanup completed"