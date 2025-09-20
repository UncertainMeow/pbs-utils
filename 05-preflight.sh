#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

echo "🔍 PBS Preflight Checks for ${PBS_HOST}"
echo "================================="

# Check if running on PBS host
echo "📍 Checking if running on correct PBS host..."
if command -v proxmox-backup-manager >/dev/null 2>&1; then
    CURRENT_HOST=$(hostname)
    echo "✅ Running on PBS node: ${CURRENT_HOST}"

    # Check dependencies
    echo "📦 Checking PBS dependencies..."
    MISSING_DEPS=()

    command -v proxmox-backup-manager >/dev/null || MISSING_DEPS+=("proxmox-backup-server")
    command -v proxmox-backup-client >/dev/null || MISSING_DEPS+=("proxmox-backup-client")
    command -v openssl >/dev/null || MISSING_DEPS+=("openssl")

    if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
        echo "❌ Missing dependencies: ${MISSING_DEPS[*]}"
        echo "   Run: apt update && apt install -y ${MISSING_DEPS[*]}"
        exit 1
    fi
    echo "✅ All dependencies found"

else
    echo "⚠️  Not running on PBS host - some checks will be skipped"
    echo "   This is expected when running preflight from a PVE node"

    # Just check network connectivity to PBS
    echo "🌐 Testing connectivity to PBS host..."
    if ping -c 2 "${PBS_HOST}" >/dev/null 2>&1; then
        echo "✅ PBS host ${PBS_HOST} is reachable"
    else
        echo "❌ Cannot reach PBS host ${PBS_HOST}"
        exit 1
    fi
fi

# Check ZFS pool (only if on PBS host)
if command -v zpool >/dev/null 2>&1 && [[ -n "${ZPOOL:-}" ]]; then
    echo "💾 Checking ZFS pool..."
    echo "   Selected pool: ${ZPOOL}"
    if zpool list "${ZPOOL}" >/dev/null 2>&1; then
        echo "✅ ZFS pool ${ZPOOL} exists"
        zpool list -o name,size,free "${ZPOOL}"
    else
        echo "❌ ZFS pool ${ZPOOL} not found"
        echo "   Available pools:"
        zpool list -H -o name 2>/dev/null || echo "   No pools found"
        exit 1
    fi
else
    echo "⚠️  Skipping ZFS checks (not on PBS host or zpool not available)"
fi

# Check TLS connectivity
echo "🔒 Getting TLS fingerprint from ${PBS_HOST}:8007..."
if FPRINT=$(openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null | openssl x509 -fingerprint -noout -sha256); then
    echo "✅ TLS connection successful"
    echo "   Fingerprint: ${FPRINT}"
else
    echo "❌ Failed to get TLS fingerprint from ${PBS_HOST}:8007"
    echo "   Check if PBS is running and accessible"
    exit 1
fi

echo ""
echo "🎉 Preflight checks completed successfully!"
echo "   PBS Host: ${PBS_HOST}"
echo "   Datastores: ${DATASTORES[*]}"
echo "   ZFS Pool: ${ZPOOL:-N/A}"