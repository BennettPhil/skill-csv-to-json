---
name: csv-to-json
description: Transform CSV files to JSON with support for custom delimiters, quoted fields, nested headers, and streaming.
version: 0.1.0
license: Apache-2.0
---

# CSV-to-JSON Transformer

Convert CSV data to JSON output, handling real-world edge cases that simple parsers miss.

## When to Use

Use this skill when the user wants to convert CSV files to JSON format, especially when:
- The CSV uses non-comma delimiters (tabs, semicolons, pipes)
- Fields contain quoted values with embedded delimiters or newlines
- Headers use dot notation that should become nested JSON objects
- The file is large and needs streaming/line-by-line processing

## Usage

```bash
# Basic conversion (reads stdin or file, writes to stdout)
./scripts/run.sh input.csv

# Custom delimiter
./scripts/run.sh input.tsv --delimiter=$'\t'

# Pipe from stdin
cat data.csv | ./scripts/run.sh

# Nested headers
./scripts/run.sh --nested input.csv

# Pretty print
./scripts/run.sh --pretty input.csv
```

## Inputs

| Argument | Required | Description |
|----------|----------|-------------|
| FILE | No | Path to CSV file. If omitted, reads stdin. |
| --delimiter=CHAR | No | Field delimiter (default: ,) |
| --nested | No | Expand dot-notation headers into nested objects |
| --pretty | No | Pretty-print JSON output |
| --no-header | No | Treat first row as data, use numeric keys |

## Outputs

- JSON array written to stdout (one object per CSV row)
- Exit code 0 on success, 1 on error
- Errors written to stderr

## Edge Cases Handled

- Quoted fields containing the delimiter character
- Quoted fields containing newlines
- Escaped quotes (double-quote escaping per RFC 4180)
- Empty fields become null in JSON
- Trailing commas / inconsistent column counts
- BOM (byte order mark) stripping
- CRLF and LF line endings

## Limitations

- Does not validate JSON Schema on output
- Nested mode only supports dot notation (not bracket notation)
- Memory-efficient but not truly streaming (buffers current record)

## Verification

Run the test suite to verify correct behavior:

```bash
./scripts/test.sh
```

All tests should pass with 0 failures.
