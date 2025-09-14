#!/usr/bin/env bash
set -euo pipefail

echo "Running complete PVE setup..."
echo "1. Post-install configuration"
./10-post-install.sh

echo "2. Microcode updates"
./20-microcode.sh

echo "3. Netdata monitoring"
./30-netdata.sh

echo "4. Kernel cleanup"
./40-kernel-clean.sh

echo "PVE setup completed successfully"