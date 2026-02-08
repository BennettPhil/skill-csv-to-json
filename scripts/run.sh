#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF' >&2
Usage: run.sh [INPUT_FILE] [OPTIONS]

Converts CSV to JSON. Reads from stdin if no file specified.

Options:
  --delimiter CHAR   Field delimiter (default: ,)
  --nested           Treat dot-notation headers as nested objects
  --array            Output as array of arrays instead of objects
  --pretty           Pretty-print JSON (default: true)
  --compact          Compact JSON (no whitespace)
  --help             Show this help message
EOF
  exit 0
}

DELIMITER=","
NESTED=false
ARRAY_MODE=false
COMPACT=false
INPUT_FILE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --help) usage ;;
    --delimiter) DELIMITER="$2"; shift 2 ;;
    --nested) NESTED=true; shift ;;
    --array) ARRAY_MODE=true; shift ;;
    --compact) COMPACT=true; shift ;;
    --pretty) shift ;;
    -*)
      echo "Error: Unknown option '$1'" >&2
      exit 1
      ;;
    *)
      INPUT_FILE="$1"
      shift
      ;;
  esac
done

if [[ -n "$INPUT_FILE" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: File not found: $INPUT_FILE" >&2
    exit 1
  fi
  INPUT=$(cat "$INPUT_FILE")
else
  INPUT=$(cat)
fi

if [[ -z "$INPUT" ]]; then
  echo "Error: No input provided" >&2
  exit 1
fi

python3 -c "
import csv, json, sys, io

input_data = sys.stdin.read()
delimiter = '$DELIMITER'
nested = $([[ "$NESTED" = true ]] && echo 'True' || echo 'False')
array_mode = $([[ "$ARRAY_MODE" = true ]] && echo 'True' || echo 'False')
compact = $([[ "$COMPACT" = true ]] && echo 'True' || echo 'False')

reader = csv.reader(io.StringIO(input_data), delimiter=delimiter)
rows = list(reader)

if not rows:
    print('[]')
    sys.exit(0)

headers = rows[0]
data_rows = rows[1:]

def set_nested(obj, keys, value):
    for key in keys[:-1]:
        if key not in obj:
            obj[key] = {}
        obj = obj[key]
    obj[keys[-1]] = value

result = []
for row in data_rows:
    if array_mode:
        result.append(row)
    else:
        obj = {}
        for i, header in enumerate(headers):
            val = row[i] if i < len(row) else ''
            if nested and '.' in header:
                keys = header.split('.')
                set_nested(obj, keys, val)
            else:
                obj[header] = val
        result.append(obj)

if compact:
    print(json.dumps(result, separators=(',', ':')))
else:
    print(json.dumps(result, indent=2))
" <<< "$INPUT"
