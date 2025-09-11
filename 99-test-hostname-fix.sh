#!/usr/bin/env bash
# Test script to validate hostname/IP address fix

echo "Testing hostname/IP validation logic..."

# Test function
test_hostname_validation() {
  local test_pbs_host="$1"
  local expected_result="$2"
  local test_name="$3"
  
  echo
  echo "Test: $test_name"
  echo "PBS_HOST=$test_pbs_host"
  
  HOSTNAME_NOW=$(hostname -s)
  
  if [[ "$test_pbs_host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Detected IP address format"
    if ip addr show | grep -q "$test_pbs_host"; then
      result="pass"
      echo "✅ IP $test_pbs_host found on this host"
    else
      result="fail"
      echo "❌ IP $test_pbs_host NOT found on this host"
    fi
  else
    echo "Detected hostname format"
    if [[ "$HOSTNAME_NOW" == "$test_pbs_host" ]]; then
      result="pass"
      echo "✅ Hostname matches: $HOSTNAME_NOW == $test_pbs_host"
    else
      result="fail"
      echo "❌ Hostname mismatch: $HOSTNAME_NOW != $test_pbs_host"
    fi
  fi
  
  if [[ "$result" == "$expected_result" ]]; then
    echo "✅ Test PASSED ($expected_result as expected)"
  else
    echo "❌ Test FAILED (got $result, expected $expected_result)"
  fi
}

echo "Current hostname: $(hostname -s)"
echo "Current IPs:"
ip addr show | grep 'inet ' | grep -v '127.0.0.1'

# Test hostname matching
test_hostname_validation "$(hostname -s)" "pass" "Current hostname should pass"
test_hostname_validation "nonexistent-host" "fail" "Wrong hostname should fail"

# Test IP matching (this will likely fail unless you have 10.203.3.97 configured)
test_hostname_validation "10.203.3.97" "fail" "Non-existent IP should fail"
test_hostname_validation "127.0.0.1" "pass" "Localhost IP should pass"

echo
echo "Test complete. The fix allows both hostname and IP address formats."
echo "When PBS_HOST is set to an IP, scripts check if that IP exists on the host."
echo "When PBS_HOST is set to a hostname, scripts check hostname matches."