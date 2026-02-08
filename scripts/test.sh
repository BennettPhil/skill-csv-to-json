#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0
TOTAL=0

pass() { ((PASS++)); ((TOTAL++)); echo "  PASS: $1"; }
fail() { ((FAIL++)); ((TOTAL++)); echo "  FAIL: $1 -- $2"; }

assert_eq() {
  local description="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    pass "$description"
  else
    fail "$description" "expected '$expected', got '$actual'"
  fi
}

assert_contains() {
  local description="$1" needle="$2" haystack="$3"
  if echo "$haystack" | grep -qF -- "$needle"; then
    pass "$description"
  else
    fail "$description" "output does not contain '$needle'"
  fi
}

assert_exit_code() {
  local description="$1" expected_code="$2"
  shift 2
  set +e
  "$@" >/dev/null 2>&1
  local actual_code=$?
  set -e
  if [ "$expected_code" -eq "$actual_code" ]; then
    pass "$description"
  else
    fail "$description" "expected exit code $expected_code, got $actual_code"
  fi
}

RUN="$SCRIPT_DIR/run.sh"

echo "Running tests for: csv-to-json"
echo "================================"

# --- Happy path tests ---
echo ""
echo "Happy path:"

# Test 1: Basic CSV
RESULT=$(printf 'name,age\nAlice,30\nBob,25' | "$RUN")
EXPECTED='[{"name": "Alice", "age": "30"}, {"name": "Bob", "age": "25"}]'
assert_eq "basic two-row CSV" "$EXPECTED" "$RESULT"

# Test 2: Single row
RESULT=$(printf 'id,val\n1,hello' | "$RUN")
assert_contains "single row has id" '"id": "1"' "$RESULT"

# Test 3: Quoted fields with commas
RESULT=$(printf '"name","addr"\n"Smith, John","123 Main, Apt 4"' | "$RUN")
assert_contains "quoted field with comma" "Smith, John" "$RESULT"

# Test 4: Custom delimiter (tab)
RESULT=$(printf 'name\tage\nAlice\t30' | "$RUN" --delimiter=$'\t')
assert_contains "tab delimiter" '"Alice"' "$RESULT"

# Test 5: Custom delimiter (semicolon)
RESULT=$(printf 'a;b\n1;2' | "$RUN" --delimiter=';')
assert_contains "semicolon delimiter" '"a": "1"' "$RESULT"

# --- Nested header tests ---
echo ""
echo "Nested headers:"

# Test 6: Dot notation nesting
RESULT=$(printf 'user.name,user.email,role\nAlice,alice@test.com,admin' | "$RUN" --nested)
assert_contains "nested user.name" '"name": "Alice"' "$RESULT"
assert_contains "nested has user object" '"user":' "$RESULT"

# --- Edge case tests ---
echo ""
echo "Edge cases:"

# Test 7: Empty input
RESULT=$(printf '' | "$RUN")
assert_eq "empty input returns []" "[]" "$RESULT"

# Test 8: Header only, no data rows
RESULT=$(printf 'a,b,c' | "$RUN")
assert_eq "header-only returns []" "[]" "$RESULT"

# Test 9: Empty fields become null
RESULT=$(printf 'a,b\n1,' | "$RUN")
assert_contains "empty field is null" '"b": null' "$RESULT"

# Test 10: Row with fewer columns than header
RESULT=$(printf 'a,b,c\n1' | "$RUN")
assert_contains "short row has null" "null" "$RESULT"

# Test 11: Escaped quotes (RFC 4180)
RESULT=$(printf '"name"\n"She said ""hello"""' | "$RUN")
assert_contains "escaped quotes" 'She said \"hello\"' "$RESULT"

# Test 12: No-header mode
RESULT=$(printf 'Alice,30\nBob,25' | "$RUN" --no-header)
assert_contains "no-header uses numeric key 0" '"0": "Alice"' "$RESULT"

# --- Pretty print test ---
echo ""
echo "Formatting:"

# Test 13: Pretty print has indentation
RESULT=$(printf 'a\n1' | "$RUN" --pretty)
LINES=$(echo "$RESULT" | wc -l | tr -d ' ')
if [ "$LINES" -gt 1 ]; then
  pass "pretty print produces multiple lines"
else
  fail "pretty print produces multiple lines" "got $LINES lines"
fi

# --- Error case tests ---
echo ""
echo "Error cases:"

# Test 14: Non-existent file
assert_exit_code "non-existent file fails" 1 "$RUN" /tmp/this-file-does-not-exist-csv2json.csv

# Test 15: Unknown option
assert_exit_code "unknown option fails" 1 "$RUN" --badopt

echo ""
echo "================================"
echo "Results: $PASS passed, $FAIL failed, $TOTAL total"
[ "$FAIL" -eq 0 ] || exit 1
