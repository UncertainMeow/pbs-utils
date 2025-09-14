#!/usr/bin/env bash
set -euo pipefail

echo "Running microcode update script..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/microcode.sh)"
echo "Microcode update completed"