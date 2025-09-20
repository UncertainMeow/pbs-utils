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

echo "✅ Running on PVE node, proceeding with kernel cleanup..."

# Download and run the community kernel cleanup script
SCRIPT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/kernel-clean.sh"
echo "📥 Downloading kernel cleanup script from community-scripts..."

if ! curl -fsSL "$SCRIPT_URL" -o /tmp/kernel-clean.sh; then
    echo "❌ Failed to download kernel cleanup script"
    exit 1
fi

echo "🚀 Running kernel cleanup script..."
bash /tmp/kernel-clean.sh

# Cleanup
rm -f /tmp/kernel-clean.sh
echo "✅ Kernel cleanup completed successfully"