#!/usr/bin/env bash
set -euo pipefail

# Change to script directory
cd "$(dirname "$0")"

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

# Check internet connectivity
if ! ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    echo "❌ No internet connectivity - required for downloading scripts"
    exit 1
fi

echo "🚀 Running complete PVE setup..."
echo "📍 Node: $(hostname)"
echo "📍 PVE Version: $(pveversion --verbose | head -1)"
echo ""

echo "1️⃣ Post-install configuration"
if ./10-post-install.sh; then
    echo "✅ Post-install completed"
else
    echo "❌ Post-install failed"
    exit 1
fi

echo ""
echo "2️⃣ Microcode updates"
if ./20-microcode.sh; then
    echo "✅ Microcode update completed"
else
    echo "❌ Microcode update failed"
    exit 1
fi

echo ""
echo "3️⃣ Netdata monitoring"
if ./30-netdata.sh; then
    echo "✅ Netdata installation completed"
else
    echo "❌ Netdata installation failed"
    exit 1
fi

echo ""
echo "4️⃣ Kernel cleanup"
if ./40-kernel-clean.sh; then
    echo "✅ Kernel cleanup completed"
else
    echo "❌ Kernel cleanup failed"
    exit 1
fi

echo ""
echo "🎉 PVE setup completed successfully on $(hostname)!"
echo "🔄 A reboot is recommended to ensure all changes take effect."