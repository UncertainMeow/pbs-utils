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

echo "✅ Running on PVE node, proceeding with Netdata installation..."

# Download and run the community netdata script
SCRIPT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/addon/netdata.sh"
echo "📥 Downloading Netdata installation script from community-scripts..."

if ! curl -fsSL "$SCRIPT_URL" -o /tmp/netdata.sh; then
    echo "❌ Failed to download Netdata script"
    exit 1
fi

echo "🚀 Running Netdata installation script..."
bash /tmp/netdata.sh

# Cleanup
rm -f /tmp/netdata.sh
echo "✅ Netdata installation completed successfully"