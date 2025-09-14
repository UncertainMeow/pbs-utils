#!/usr/bin/env bash
set -euo pipefail

echo "=== PBS-Utils Validation ==="

# Test 1: Environment file
echo "✓ Testing 00-env.sh..."
source ./00-env.sh
echo "  PBS_HOST: $PBS_HOST"
echo "  DATASTORES: ${DATASTORES[*]}"

# Test 2: PVE utilities exist
echo "✓ Testing pve-utils..."
for script in pve-utils/*.sh; do
  if [[ -x "$script" ]]; then
    echo "  ✓ $(basename "$script") is executable"
  else
    echo "  ✗ $(basename "$script") not executable"
    exit 1
  fi
done

# Test 3: PBS connectivity (if on PBS host)
if command -v proxmox-backup-manager >/dev/null 2>&1; then
  echo "✓ PBS tools available - running on PBS host"
  if proxmox-backup-manager node show >/dev/null 2>&1; then
    echo "  ✓ PBS service is running"
  else
    echo "  ✗ PBS service issues"
  fi
else
  echo "✓ Not on PBS host - skipping PBS tests"
fi

# Test 4: Key PBS scripts syntax
echo "✓ Testing PBS script syntax..."
for script in 05-preflight.sh 40-pve-add-storage.sh 50-pbs-policies.sh 70-test.sh; do
  if bash -n "$script"; then
    echo "  ✓ $script syntax OK"
  else
    echo "  ✗ $script syntax error"
    exit 1
  fi
done

echo "=== All validations passed ==="