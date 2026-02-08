#!/usr/bin/env bash
set -euo pipefail

# CSV-to-JSON Transformer
# Handles: custom delimiters, quoted fields, nested headers, edge cases

DELIMITER=","
NESTED=false
PRETTY=false
NO_HEADER=false
INPUT_FILE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case "$1" in
    --delimiter=*) DELIMITER="${1#*=}"; shift ;;
    --nested) NESTED=true; shift ;;
    --pretty) PRETTY=true; shift ;;
    --no-header) NO_HEADER=true; shift ;;
    -*) echo "Unknown option: $1" >&2; exit 1 ;;
    *) INPUT_FILE="$1"; shift ;;
  esac
done

# Use Python for robust CSV parsing (available on macOS/Linux)
python3 -c "
import csv
import json
import sys
import io

delimiter = '''${DELIMITER}'''
nested = '${NESTED}' == 'true'
pretty = '${PRETTY}' == 'true'
no_header = '${NO_HEADER}' == 'true'
input_file = '${INPUT_FILE}'

def set_nested(obj, key_path, value):
    keys = key_path.split('.')
    current = obj
    for k in keys[:-1]:
        if k not in current:
            current[k] = {}
        current = current[k]
    current[keys[-1]] = value

def process_value(val):
    if val == '':
        return None
    return val

try:
    if input_file:
        f = open(input_file, 'r', encoding='utf-8-sig')
    else:
        f = io.TextIOWrapper(sys.stdin.buffer, encoding='utf-8-sig')
    
    reader = csv.reader(f, delimiter=delimiter)
    rows = list(reader)
    f.close() if input_file else None
    
    if not rows:
        print('[]')
        sys.exit(0)
    
    if no_header:
        headers = [str(i) for i in range(len(rows[0]))]
        data_rows = rows
    else:
        headers = [h.strip() for h in rows[0]]
        data_rows = rows[1:]
    
    if not data_rows:
        print('[]')
        sys.exit(0)
    
    result = []
    for row in data_rows:
        obj = {}
        for i, header in enumerate(headers):
            val = process_value(row[i]) if i < len(row) else None
            if nested and '.' in header:
                set_nested(obj, header, val)
            else:
                obj[header] = val
        result.append(obj)
    
    indent = 2 if pretty else None
    print(json.dumps(result, indent=indent, ensure_ascii=False))
except Exception as e:
    print(f'Error: {e}', file=sys.stderr)
    sys.exit(1)
"
