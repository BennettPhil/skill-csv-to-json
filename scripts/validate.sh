#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

check() {
  local desc="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc -- expected '$expected', got '$actual'"
  fi
}

check_contains() {
  local desc="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc -- output does not contain '$needle'"
  fi
}

echo "Validating csv-to-json..."

# Test 1: Basic conversion
result=$(echo 'name,age
Alice,30
Bob,25' | "$SCRIPT_DIR/run.sh" 2>/dev/null)
check_contains "basic conversion has Alice" '"name":"Alice"' "$result"
check_contains "basic conversion has Bob" '"name":"Bob"' "$result"

# Test 2: OK message
ok_msg=$(echo 'name,age
Alice,30' | "$SCRIPT_DIR/run.sh" 2>&1 1>/dev/null)
check_contains "OK message present" "OK: converted 1 rows" "$ok_msg"

# Test 3: Valid JSON
echo 'name,age
Alice,30
Bob,25' | "$SCRIPT_DIR/run.sh" 2>/dev/null | python3 -m json.tool > /dev/null 2>&1 && ((PASS++)) && echo "  PASS: output is valid JSON" || { ((FAIL++)); echo "  FAIL: output is not valid JSON"; }

# Test 4: Quoted fields with commas
result=$(echo 'name,description
Alice,"likes cats, dogs"' | "$SCRIPT_DIR/run.sh" 2>/dev/null)
check_contains "quoted fields" 'likes cats, dogs' "$result"

# Test 5: Nested headers
result=$(echo 'user.name,user.email,role
Alice,alice@example.com,admin' | "$SCRIPT_DIR/run.sh" 2>/dev/null)
check_contains "nested header user" '"user":{' "$result"

echo ""
echo "Results: $PASS passed, $FAIL failed"
if [[ $FAIL -eq 0 ]]; then
  echo "PASS: all checks passed"
else
  echo "FAIL: $FAIL checks failed"
  exit 1
fi
