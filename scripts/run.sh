#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  cat <<'USAGE'
Usage: run.sh [OPTIONS] [<input-file>]

Convert CSV files to JSON.

Arguments:
  <input-file>           Path to the CSV file (omit if using --stdin)

Options:
  --stdin                Read CSV from stdin
  --delimiter <char>     Field delimiter (default: ",")
  --output <path>        Write output to file instead of stdout
  --compact              Compact JSON output (no indentation)
  --ndjson               Output one JSON object per line (NDJSON)
  --infer-types          Convert numbers and booleans to native types
  --skip-lines <n>       Skip n lines before reading headers
  --help                 Show this help message
USAGE
}

INPUT=""
FROM_STDIN=false
DELIMITER=","
OUTPUT=""
COMPACT=false
NDJSON=false
INFER_TYPES=false
SKIP_LINES=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --stdin) FROM_STDIN=true; shift ;;
    --delimiter) DELIMITER="$2"; shift 2 ;;
    --output) OUTPUT="$2"; shift 2 ;;
    --compact) COMPACT=true; shift ;;
    --ndjson) NDJSON=true; shift ;;
    --infer-types) INFER_TYPES=true; shift ;;
    --skip-lines) SKIP_LINES="$2"; shift 2 ;;
    --help) usage; exit 0 ;;
    -*) echo "Error: Unknown option: $1" >&2; usage >&2; exit 1 ;;
    *) INPUT="$1"; shift ;;
  esac
done

if [ "$FROM_STDIN" = false ] && [ -z "$INPUT" ]; then
  echo "Error: Input file or --stdin is required." >&2
  usage >&2
  exit 1
fi

if [ "$FROM_STDIN" = false ] && [ ! -f "$INPUT" ]; then
  echo "Error: File not found: $INPUT" >&2
  exit 1
fi

ARGS=()
ARGS+=("--delimiter" "$DELIMITER")
ARGS+=("--skip-lines" "$SKIP_LINES")
[ "$COMPACT" = true ] && ARGS+=("--compact")
[ "$NDJSON" = true ] && ARGS+=("--ndjson")
[ "$INFER_TYPES" = true ] && ARGS+=("--infer-types")
[ -n "$OUTPUT" ] && ARGS+=("--output" "$OUTPUT")

if [ "$FROM_STDIN" = true ]; then
  python3 "$SCRIPT_DIR/convert.py" --stdin "${ARGS[@]}"
else
  python3 "$SCRIPT_DIR/convert.py" "$INPUT" "${ARGS[@]}"
fi
