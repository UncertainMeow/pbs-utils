#!/usr/bin/env bash
set -euo pipefail

# Check if running on PVE node
if ! command -v pvesh >/dev/null 2>&1; then
    echo "❌ Not running on a PVE node (pvesh command not found)"
    echo "   This script must be run on a Proxmox VE node"
    exit 1
fi

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo "❌ This script must be run as root"
    exit 1
fi

echo "✅ Running on PVE node, proceeding with post-install configuration..."

# Download and run the community post-install script
SCRIPT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/post-pve-install.sh"
echo "📥 Downloading post-install script from community-scripts..."

if ! curl -fsSL "$SCRIPT_URL" -o /tmp/post-pve-install.sh; then
    echo "❌ Failed to download post-install script"
    exit 1
fi

echo "🚀 Running Proxmox post-install script..."
bash /tmp/post-pve-install.sh

# Cleanup
rm -f /tmp/post-pve-install.sh
echo "✅ Post-install completed successfully"