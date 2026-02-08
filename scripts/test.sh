#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN="$SCRIPT_DIR/run.sh"
PASS=0; FAIL=0; TOTAL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  ((TOTAL++))
  if [ "$expected" = "$actual" ]; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc"
    echo "    expected: $expected"
    echo "    actual:   $actual"
  fi
}

assert_contains() {
  local desc="$1" needle="$2" haystack="$3"
  ((TOTAL++))
  if echo "$haystack" | grep -qF -- "$needle"; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc (output missing '$needle')"
  fi
}

assert_exit_code() {
  local desc="$1" expected="$2"
  shift 2
  local output
  set +e; output=$("$@" 2>&1); local actual=$?; set -e
  ((TOTAL++))
  if [ "$expected" -eq "$actual" ]; then
    ((PASS++)); echo "  PASS: $desc"
  else
    ((FAIL++)); echo "  FAIL: $desc (expected exit $expected, got $actual)"
  fi
}

echo "=== Tests for csv-to-json ==="

# --- Core functionality tests ---
echo "Core:"

# Basic CSV to JSON
result=$(echo -e "name,age\nAlice,30\nBob,25" | "$RUN")
assert_contains "basic csv has name field" '"name"' "$result"
assert_contains "basic csv has Alice" '"Alice"' "$result"

# Custom delimiter
result=$(echo -e "name;age\nAlice;30" | "$RUN" --delimiter ";")
assert_contains "semicolon delimiter works" '"Alice"' "$result"

# Quoted fields
result=$(echo -e 'name,bio\nAlice,"likes, commas"' | "$RUN")
assert_contains "quoted field preserved" "likes, commas" "$result"

# Empty input
echo "Input validation:"
assert_exit_code "empty stdin errors" 1 "$RUN" < /dev/null

# Help flag
echo "Help:"
result=$("$RUN" --help 2>&1)
assert_contains "help flag works" "Usage:" "$result"

# Nested headers (dot notation)
echo "Advanced:"
result=$(echo -e "user.name,user.age\nAlice,30" | "$RUN" --nested)
assert_contains "nested headers create objects" '"user"' "$result"

echo ""
echo "=== Results: $PASS/$TOTAL passed ==="
[ "$FAIL" -eq 0 ] || { echo "BLOCKED: $FAIL test(s) failed"; exit 1; }
