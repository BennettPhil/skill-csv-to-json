#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

check() {
  local desc="$1" expected="$2" actual="$3"
  # Compare JSON semantically using Python
  if python3 -c "
import json, sys
a = json.loads(sys.argv[1])
b = json.loads(sys.argv[2])
sys.exit(0 if a == b else 1)
" "$expected" "$actual" 2>/dev/null; then
    ((PASS++))
    echo "  PASS: $desc"
  else
    ((FAIL++))
    echo "  FAIL: $desc"
    echo "    Expected: $(echo "$expected" | head -1)"
    echo "    Got:      $(echo "$actual" | head -1)"
  fi
}

check_text() {
  local desc="$1" expected="$2" actual="$3"
  expected="$(echo "$expected" | sed 's/[[:space:]]*$//')"
  actual="$(echo "$actual" | sed 's/[[:space:]]*$//')"
  if [ "$expected" = "$actual" ]; then
    ((PASS++))
    echo "  PASS: $desc"
  else
    ((FAIL++))
    echo "  FAIL: $desc"
    echo "    Expected: $(echo "$expected" | head -1)"
    echo "    Got:      $(echo "$actual" | head -1)"
  fi
}

TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

echo "Testing csv-to-json examples"
echo "============================"

# --- Basic example ---
echo ""
echo "Basic:"

printf 'name,email,age\nAlice,alice@example.com,30\nBob,bob@example.com,25\n' > "$TMPDIR_TEST/users.csv"

actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/users.csv")"
expected='[
  {"name": "Alice", "email": "alice@example.com", "age": "30"},
  {"name": "Bob", "email": "bob@example.com", "age": "25"}
]'
check "basic CSV to JSON" "$expected" "$actual"

# Stdin
actual="$(echo 'name,score
Charlie,95' | "$SCRIPT_DIR/run.sh" --stdin)"
expected='[
  {"name": "Charlie", "score": "95"}
]'
check "stdin input" "$expected" "$actual"

# --- Custom delimiter ---
echo ""
echo "Custom delimiter:"

printf 'product\tprice\tquantity\nWidget\t9.99\t100\nGadget\t24.50\t50\n' > "$TMPDIR_TEST/data.tsv"
actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/data.tsv" --delimiter "\t")"
expected='[
  {"product": "Widget", "price": "9.99", "quantity": "100"},
  {"product": "Gadget", "price": "24.50", "quantity": "50"}
]'
check "tab delimiter" "$expected" "$actual"

# --- Nested headers ---
echo ""
echo "Nested headers:"

printf 'name,address.city,address.state,address.zip\nJane Doe,Portland,OR,97201\nJohn Smith,Seattle,WA,98101\n' > "$TMPDIR_TEST/employees.csv"
actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/employees.csv")"
expected='[
  {"name": "Jane Doe", "address": {"city": "Portland", "state": "OR", "zip": "97201"}},
  {"name": "John Smith", "address": {"city": "Seattle", "state": "WA", "zip": "98101"}}
]'
check "dot-notation nested headers" "$expected" "$actual"

# --- Quoted fields ---
echo ""
echo "Quoted fields:"

printf 'name,note,city\n"Smith, John","Said ""hello""",Portland\n"Doe, Jane","Line 1",Seattle\n' > "$TMPDIR_TEST/contacts.csv"
actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/contacts.csv")"
expected='[
  {"name": "Smith, John", "note": "Said \"hello\"", "city": "Portland"},
  {"name": "Doe, Jane", "note": "Line 1", "city": "Seattle"}
]'
check "quoted fields with commas and escaped quotes" "$expected" "$actual"

# --- Compact output ---
echo ""
echo "Compact:"

actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/users.csv" --compact)"
expected='[{"name":"Alice","email":"alice@example.com","age":"30"},{"name":"Bob","email":"bob@example.com","age":"25"}]'
check "compact output" "$expected" "$actual"

# --- NDJSON ---
echo ""
echo "NDJSON:"

actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/users.csv" --ndjson)"
expected='{"name": "Alice", "email": "alice@example.com", "age": "30"}
{"name": "Bob", "email": "bob@example.com", "age": "25"}'
check_text "ndjson output" "$expected" "$actual"

# --- Type inference ---
echo ""
echo "Type inference:"

printf 'name,age,active\nAlice,30,true\nBob,25,false\n' > "$TMPDIR_TEST/typed.csv"
actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/typed.csv" --infer-types)"
expected='[
  {"name": "Alice", "age": 30, "active": true},
  {"name": "Bob", "age": 25, "active": false}
]'
check "type inference" "$expected" "$actual"

# --- Edge cases ---
echo ""
echo "Edge cases:"

actual="$(echo "" | "$SCRIPT_DIR/run.sh" --stdin)"
check "empty input" "[]" "$actual"

actual="$(echo "name,age" | "$SCRIPT_DIR/run.sh" --stdin)"
check "header only" "[]" "$actual"

printf 'name,email,phone\nAlice,,555-0100\n,bob@example.com,\n' > "$TMPDIR_TEST/empty-fields.csv"
actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/empty-fields.csv")"
expected='[
  {"name": "Alice", "email": "", "phone": "555-0100"},
  {"name": "", "email": "bob@example.com", "phone": ""}
]'
check "empty fields" "$expected" "$actual"

printf 'a,b,c\n1,2\n3\n' > "$TMPDIR_TEST/fewer-cols.csv"
actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/fewer-cols.csv")"
expected='[
  {"a": "1", "b": "2", "c": ""},
  {"a": "3", "b": "", "c": ""}
]'
check "fewer columns than headers" "$expected" "$actual"

printf 'a,b\n1,2,3\n4,5,6,7\n' > "$TMPDIR_TEST/more-cols.csv"
actual="$("$SCRIPT_DIR/run.sh" "$TMPDIR_TEST/more-cols.csv")"
expected='[
  {"a": "1", "b": "2"},
  {"a": "4", "b": "5"}
]'
check "more columns than headers" "$expected" "$actual"

# Error case
set +e
"$SCRIPT_DIR/run.sh" nonexistent.csv 2>/dev/null
exit_code=$?
set -e
if [ "$exit_code" -ne 0 ]; then
  ((PASS++)); echo "  PASS: file not found exits non-zero"
else
  ((FAIL++)); echo "  FAIL: file not found should exit non-zero"
fi

echo ""
echo "============================"
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ] || exit 1
