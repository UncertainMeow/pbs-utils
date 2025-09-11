#!/usr/bin/env bash
# Validation script to check our fixes without requiring PBS environment
set -euo pipefail

echo "=== PBS-Utils Fix Validation ==="
echo

# Check for removed problematic flags
echo "1. Checking for removed --output-format flag..."
if grep -r "output-format" *.sh 2>/dev/null | grep -v "99-validate-fixes.sh"; then
  echo "❌ FAIL: --output-format flag still present in scripts"
  exit 1
else
  echo "✅ PASS: --output-format flag removed from scripts"
fi

echo

# Check for backward compatibility in ACL script
echo "2. Checking ACL script backward compatibility..."
if grep -q "DatastoreAudit.*--auth-id" 30-pbs-acl.sh && grep -q "Fallback to old syntax" 30-pbs-acl.sh; then
  echo "✅ PASS: ACL script has backward compatibility"
else
  echo "❌ FAIL: ACL script missing backward compatibility"
  exit 1
fi

echo

# Check for backward compatibility in token script
echo "3. Checking token script backward compatibility..."
if grep -q "Try without --privs first" 10-pbs-user-token.sh && grep -q "Fallback to old syntax with --privs" 10-pbs-user-token.sh; then
  echo "✅ PASS: Token script has backward compatibility"
else
  echo "❌ FAIL: Token script missing backward compatibility"
  exit 1
fi

echo

# Check test script uses correct commands
echo "4. Checking test script uses server-side commands..."
if grep -q "proxmox-backup-manager status" 70-test.sh && grep -q "proxmox-backup-manager datastore list" 70-test.sh; then
  echo "✅ PASS: Test script uses correct server-side commands"
else
  echo "❌ FAIL: Test script doesn't use correct commands"
  exit 1
fi

echo

# Check invalid client command removed
echo "5. Checking invalid client command removed..."
if grep -q "proxmox-backup-client datastore" 70-test.sh; then
  echo "❌ FAIL: Invalid client command still present"
  exit 1
else
  echo "✅ PASS: Invalid client command removed"
fi

echo

# Check ZPOOL_PREFERRED is properly commented
echo "6. Checking ZPOOL_PREFERRED config..."
if grep -q "^# ZPOOL_PREFERRED=" 00-env.sh; then
  echo "✅ PASS: ZPOOL_PREFERRED properly commented out"
else
  echo "❌ FAIL: ZPOOL_PREFERRED not properly configured"
  exit 1
fi

echo

# Check for syntax errors in all scripts
echo "7. Checking for bash syntax errors..."
ERROR_COUNT=0
for script in *.sh; do
  if [[ "$script" == "99-validate-fixes.sh" ]]; then
    continue
  fi
  if bash -n "$script" 2>/dev/null; then
    echo "✅ $script: syntax OK"
  else
    echo "❌ $script: syntax ERROR"
    ERROR_COUNT=$((ERROR_COUNT + 1))
  fi
done

if [[ $ERROR_COUNT -gt 0 ]]; then
  echo "❌ FAIL: $ERROR_COUNT script(s) have syntax errors"
  exit 1
fi

echo

echo "=== All Validation Checks Passed! ==="
echo "The PBS-Utils repository has been successfully fixed:"
echo "- Removed --output-format flag that doesn't exist in your PBS version"
echo "- Added backward-compatible ACL syntax (new -> old fallback)"
echo "- Added backward-compatible token creation (new -> old fallback)"
echo "- Fixed test script to use correct server-side commands"
echo "- Reverted ZPOOL_PREFERRED config to original state"
echo
echo "Ready for testing on actual PBS environment!"