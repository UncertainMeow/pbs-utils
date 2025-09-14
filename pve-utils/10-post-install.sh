#!/usr/bin/env bash
set -euo pipefail

echo "Running Proxmox post-install script..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh)"
echo "Post-install completed"