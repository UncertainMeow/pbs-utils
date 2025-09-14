#!/usr/bin/env bash
set -euo pipefail

echo "Running Netdata installation script..."
bash -c "$(curl -fsSL https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/netdata.sh)"
echo "Netdata installation completed"