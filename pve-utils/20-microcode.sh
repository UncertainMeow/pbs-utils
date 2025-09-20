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

echo "✅ Running on PVE node, proceeding with microcode update..."

# Download and run the community microcode script
SCRIPT_URL="https://raw.githubusercontent.com/community-scripts/ProxmoxVE/main/tools/pve/microcode.sh"
echo "📥 Downloading microcode update script from community-scripts..."

if ! curl -fsSL "$SCRIPT_URL" -o /tmp/microcode.sh; then
    echo "❌ Failed to download microcode script"
    exit 1
fi

echo "🚀 Running microcode update script..."
bash /tmp/microcode.sh

# Cleanup
rm -f /tmp/microcode.sh
echo "✅ Microcode update completed successfully"