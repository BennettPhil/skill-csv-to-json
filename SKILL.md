---
name: csv-to-json
description: Convert CSV files to JSON with support for custom delimiters, quoted fields, and nested headers via dot notation.
version: 0.1.0
license: Apache-2.0
---

# csv-to-json

Converts CSV data to JSON arrays or objects, handling edge cases like quoted fields, custom delimiters, and nested headers using dot notation.

## Purpose

CSV-to-JSON conversion seems simple until you hit real-world data: fields with commas inside quotes, tabs as delimiters, headers like `address.city` that should become nested objects. This skill handles all of that with a pure awk implementation.

## Contract

- Accepts CSV via stdin or file argument
- Outputs a JSON array of objects to stdout
- Headers from the first row become object keys
- Dot-notation headers (e.g., `user.name`) produce nested objects
- Quoted fields (double-quote) are handled correctly, including embedded commas
- Custom delimiters via `--delimiter`
- Exit 0 on success (last stdout line: `OK: converted N rows`)
- Exit 1 on runtime error (stderr: `ERROR: <description>`)
- Exit 2 on invalid input/usage (stderr: `ERROR: <description>`)

## Usage

```bash
# Convert a CSV file
./scripts/run.sh data.csv
# Output: [{"name":"Alice","age":"30"},{"name":"Bob","age":"25"}]
# OK: converted 2 rows

# Convert from stdin with tab delimiter
cat data.tsv | ./scripts/run.sh --delimiter '\t'

# Convert with nested headers
echo 'user.name,user.email,role
Alice,alice@example.com,admin' | ./scripts/run.sh
# Output: [{"user":{"name":"Alice","email":"alice@example.com"},"role":"admin"}]
# OK: converted 1 rows
```

## Arguments and Options

| Flag | Required | Default | Description |
|------|----------|---------|-------------|
| FILE | No | stdin | Path to CSV file to convert |
| --delimiter | No | `,` | Field delimiter character |
| --no-header | No | false | Treat first row as data, use col0, col1... as keys |
| --pretty | No | false | Pretty-print JSON output |
| --help | No | - | Show usage information |
| --validate | No | - | Run self-check and report pass/fail |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Runtime error (e.g., malformed CSV) |
| 2 | Invalid input / usage error |

## Validation

After running, an agent can verify:
1. Output is valid JSON (pipe through `python3 -m json.tool` or `jq .`)
2. The last line of stderr contains `OK: converted N rows` where N matches expected row count
3. Run `./scripts/validate.sh` for a built-in self-check
