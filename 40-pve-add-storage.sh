#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/00-env.sh"

# Check if running on PVE node
if ! command -v pvesh >/dev/null; then
  echo "❌ pvesh command not found - are you running this on a PVE node?"
  echo "   This script must be run on a Proxmox VE node"
  exit 1
fi

# Check if running as root (needed for apt install)
if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root"
  exit 1
fi

echo "✅ Running on PVE node: $(hostname)"

# Check dependencies
echo "📦 Checking dependencies..."
MISSING_DEPS=()
command -v jq >/dev/null || MISSING_DEPS+=("jq")
command -v openssl >/dev/null || MISSING_DEPS+=("openssl")

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
  echo "📥 Installing missing dependencies: ${MISSING_DEPS[*]}..."
  if apt update && apt install -y "${MISSING_DEPS[@]}"; then
    echo "✅ Dependencies installed successfully"
  else
    echo "❌ Failed to install dependencies"
    exit 1
  fi
else
  echo "✅ All dependencies found"
fi

# Check PBS_SECRET environment variable
echo "🔐 Checking PBS authentication..."
if [[ -z "${PBS_SECRET:-}" ]]; then
  echo "❌ PBS_SECRET environment variable not set"
  echo "   Export PBS_SECRET with your token secret:"
  echo "   export PBS_SECRET='your-token-secret-here'"
  exit 1
fi

TOKEN_ID="${PBS_USER}!${PBS_TOKEN_NAME}"
echo "✅ Using token: ${TOKEN_ID}"

# Test connectivity to PBS
echo "🌐 Testing connectivity to PBS host ${PBS_HOST}..."
if ! ping -c 2 "${PBS_HOST}" >/dev/null 2>&1; then
  echo "❌ Cannot reach PBS host ${PBS_HOST}"
  echo "   Check network connectivity and DNS resolution"
  exit 1
fi

# Get SSL fingerprint
echo "🔒 Getting SSL fingerprint from ${PBS_HOST}:8007..."
if FPRINT=$(openssl s_client -connect "${PBS_HOST}:8007" -showcerts </dev/null 2>/dev/null | openssl x509 -fingerprint -noout -sha256 | cut -d'=' -f2); then
  echo "✅ SSL Fingerprint: $FPRINT"
else
  echo "❌ Failed to get SSL fingerprint from ${PBS_HOST}:8007"
  echo "   Check if PBS is running and accessible on port 8007"
  exit 1
fi

# Add storage for each datastore
echo ""
echo "💾 Adding PBS storage configurations..."
for DS in "${DATASTORES[@]}"; do
  NAME="pbs-${DS}"
  echo "📂 Processing datastore: ${DS} (storage name: ${NAME})"

  # Check if storage already exists
  echo "🔍 Checking if storage $NAME exists..."
  if pvesh get /storage --output-format json 2>/dev/null | jq -r '.[].storage' 2>/dev/null | grep -qx "$NAME"; then
    echo "✅ Storage $NAME already exists - skipping"
    continue
  fi

  # Create the storage configuration
  # For PBS 4.0+, use the full token ID as username and secret as password
  echo "🔧 Creating storage configuration..."
  if pvesh create /storage --storage "$NAME" --type pbs \
    --server "$PBS_HOST" \
    --datastore "$DS" \
    --username "${PBS_USER}!${PBS_TOKEN_NAME}" \
    --password "$PBS_SECRET" \
    --fingerprint "$FPRINT" \
    --content "backup"; then
    echo "✅ Added storage $NAME -> ${PBS_HOST}:${DS}"
  else
    echo "❌ Failed to add storage $NAME"
    echo "   Check PBS permissions and datastore existence"
    echo "   Token: ${PBS_USER}!${PBS_TOKEN_NAME}"
    echo "   Secret: ${PBS_SECRET:0:8}..."
    exit 1
  fi
done

echo ""
echo "📋 Current PBS storage configurations:"
pvesh get /storage | jq -r '.[] | select(.type=="pbs") | "\(.storage) -> \(.server):\(.datastore)"' || echo "No PBS storage found"

echo ""
echo "🎉 PBS storage configuration completed successfully!"
echo "   Added storage for datastores: ${DATASTORES[*]}"