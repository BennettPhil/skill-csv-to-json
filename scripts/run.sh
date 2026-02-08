#!/usr/bin/env bash
set -euo pipefail

# run.sh — Convert CSV to JSON
# Usage: ./run.sh [OPTIONS] [FILE]

DELIMITER=","
NO_HEADER=false
PRETTY=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --delimiter) DELIMITER="$2"; shift 2 ;;
    --no-header) NO_HEADER=true; shift ;;
    --pretty) PRETTY=true; shift ;;
    --validate)
      SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
      exec "$SCRIPT_DIR/validate.sh"
      ;;
    --help)
      echo "Usage: run.sh [OPTIONS] [FILE]"
      echo ""
      echo "Convert CSV to JSON."
      echo ""
      echo "Options:"
      echo "  --delimiter CHAR   Field delimiter (default: ,)"
      echo "  --no-header        First row is data, not headers"
      echo "  --pretty           Pretty-print JSON output"
      echo "  --validate         Run self-check"
      echo "  --help             Show this help"
      exit 0
      ;;
    -*)
      echo "ERROR: unknown option: $1" >&2
      exit 2
      ;;
    *)
      if [[ -z "${INPUT_FILE:-}" ]]; then
        INPUT_FILE="$1"; shift
      else
        echo "ERROR: unexpected argument: $1" >&2
        exit 2
      fi
      ;;
  esac
done

# Handle tab delimiter
if [[ "$DELIMITER" == '\t' || "$DELIMITER" == "\\t" ]]; then
  DELIMITER=$'\t'
fi

# Get input
if [[ -n "${INPUT_FILE:-}" ]]; then
  if [[ ! -f "$INPUT_FILE" ]]; then
    echo "ERROR: file not found: $INPUT_FILE" >&2
    exit 2
  fi
  CSV_DATA=$(cat "$INPUT_FILE")
elif [[ -t 0 ]]; then
  echo "ERROR: no CSV input provided" >&2
  echo "Usage: run.sh [OPTIONS] [FILE]" >&2
  exit 2
else
  CSV_DATA=$(cat)
fi

if [[ -z "$CSV_DATA" ]]; then
  echo "ERROR: empty CSV input" >&2
  exit 2
fi

# Convert CSV to JSON using awk
RESULT=$(echo "$CSV_DATA" | awk -v delim="$DELIMITER" -v no_header="$NO_HEADER" -v pretty="$PRETTY" '
BEGIN {
  FS = delim
  row_count = 0
}

function parse_csv_line(line, fields,    n, i, in_quote, field, c, chars_count) {
  n = 0
  in_quote = 0
  field = ""
  chars_count = split(line, chars, "")

  for (i = 1; i <= chars_count; i++) {
    c = chars[i]
    if (c == "\"") {
      if (in_quote && i < chars_count && chars[i+1] == "\"") {
        field = field "\""
        i++
      } else {
        in_quote = !in_quote
      }
    } else if (c == delim && !in_quote) {
      n++
      fields[n] = field
      field = ""
    } else {
      field = field c
    }
  }
  n++
  fields[n] = field
  return n
}

function json_escape(s) {
  gsub(/\\/, "\\\\", s)
  gsub(/"/, "\\\"", s)
  gsub(/\t/, "\\t", s)
  gsub(/\n/, "\\n", s)
  gsub(/\r/, "\\r", s)
  return s
}

function set_nested(obj_id, key, value,    parts, n, i, current, part) {
  # Handle dot-notation keys by building nested path
  n = split(key, parts, "\\.")
  if (n == 1) {
    flat_keys[obj_id, key] = value
    return
  }
  # For nested, store the path
  nested_paths[obj_id, key] = value
}

NR == 1 {
  if (no_header == "true") {
    # Generate column names
    num_cols = parse_csv_line($0, row_fields)
    for (i = 1; i <= num_cols; i++) {
      headers[i] = "col" (i-1)
    }
    num_headers = num_cols
    # Process first row as data
    row_count++
    for (i = 1; i <= num_cols; i++) {
      data[row_count, i] = row_fields[i]
    }
  } else {
    num_headers = parse_csv_line($0, headers)
    # Trim whitespace from headers
    for (i = 1; i <= num_headers; i++) {
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", headers[i])
    }
  }
  next
}

{
  row_count++
  num_fields = parse_csv_line($0, row_fields)
  for (i = 1; i <= num_fields && i <= num_headers; i++) {
    gsub(/^[[:space:]]+|[[:space:]]+$/, "", row_fields[i])
    data[row_count, i] = row_fields[i]
  }
}

END {
  indent = ""
  nl = ""
  if (pretty == "true") {
    indent = "  "
    nl = "\n"
  }

  printf "[" nl

  for (r = 1; r <= row_count; r++) {
    # Check for nested headers (dot notation)
    has_nested = 0
    for (i = 1; i <= num_headers; i++) {
      if (index(headers[i], ".") > 0) {
        has_nested = 1
        break
      }
    }

    if (has_nested) {
      # Build nested objects
      # First pass: collect all nested paths
      delete nested_obj
      delete flat_obj
      for (i = 1; i <= num_headers; i++) {
        val = json_escape(data[r, i])
        h = headers[i]
        n_parts = split(h, parts, "\\.")
        if (n_parts == 1) {
          flat_obj[h] = val
        } else {
          # Store top-level key and sub-key
          top = parts[1]
          subkey = parts[2]
          nested_obj[top, subkey] = val
          if (!(top in nested_tops)) {
            nested_top_order[++nested_top_count] = top
          }
          nested_tops[top] = 1
        }
      }

      # Build JSON object
      if (pretty == "true") printf "  "
      printf "{"
      first = 1

      for (i = 1; i <= num_headers; i++) {
        h = headers[i]
        if (index(h, ".") > 0) {
          # Check if we already output this top-level
          split(h, parts, "\\.")
          top = parts[1]
          if (top in done_tops) continue
          done_tops[top] = 1

          if (!first) printf ","
          if (pretty == "true") printf nl indent indent
          printf "\"%s\":{", top

          # Output all sub-keys for this top
          sub_first = 1
          for (j = 1; j <= num_headers; j++) {
            if (index(headers[j], top ".") == 1) {
              split(headers[j], sp, "\\.")
              sk = sp[2]
              if (!sub_first) printf ","
              printf "\"%s\":\"%s\"", sk, json_escape(data[r, j])
              sub_first = 0
            }
          }
          printf "}"
          first = 0
        } else {
          if (!first) printf ","
          if (pretty == "true") printf nl indent indent
          printf "\"%s\":\"%s\"", h, json_escape(data[r, i])
          first = 0
        }
      }
      delete done_tops
      delete nested_tops
      nested_top_count = 0

      printf "}"
    } else {
      # Simple flat object
      if (pretty == "true") printf "  "
      printf "{"
      for (i = 1; i <= num_headers; i++) {
        if (i > 1) printf ","
        if (pretty == "true" && i > 1) printf " "
        printf "\"%s\":\"%s\"", headers[i], json_escape(data[r, i])
      }
      printf "}"
    }

    if (r < row_count) printf ","
    printf nl
  }

  printf "]" nl

  # Print row count to stderr
  printf "OK: converted %d rows\n", row_count > "/dev/stderr"
}
')

echo "$RESULT"
