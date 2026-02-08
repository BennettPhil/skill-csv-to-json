---
name: csv-to-json
description: Converts CSV to JSON with support for custom delimiters, quoted fields, and nested dot-notation headers.
version: 0.1.0
license: Apache-2.0
---

# CSV to JSON

## Purpose

Transform CSV data into JSON. Handles common edge cases gracefully: quoted fields with embedded delimiters, custom separators, and dot-notation headers that expand into nested objects.

## Quick Start

```bash
$ echo -e "name,age\nAlice,30\nBob,25" | ./scripts/run.sh
[
  {"name": "Alice", "age": "30"},
  {"name": "Bob", "age": "25"}
]
```

## Usage Examples

### Custom Delimiter

```bash
$ echo -e "name;age\nAlice;30" | ./scripts/run.sh --delimiter ";"
[{"name": "Alice", "age": "30"}]
```

### Nested Headers

```bash
$ echo -e "user.name,user.email\nAlice,alice@example.com" | ./scripts/run.sh --nested
[{"user": {"name": "Alice", "email": "alice@example.com"}}]
```

### Compact Output

```bash
$ echo -e "a,b\n1,2" | ./scripts/run.sh --compact
[{"a":"1","b":"2"}]
```

### From File

```bash
$ ./scripts/run.sh data.csv
```

## Options Reference

| Flag            | Default | Description                              |
|-----------------|---------|------------------------------------------|
| `--delimiter C` | `,`     | Field delimiter character                |
| `--nested`      | false   | Expand dot-notation headers to objects   |
| `--compact`     | false   | Compact JSON output                      |
| `--array`       | false   | Output as array of arrays (no headers)   |
| `--help`        |         | Show usage information                   |

## Error Handling

| Exit Code | Meaning            |
|-----------|--------------------|
| 0         | Success            |
| 1         | Usage/input error  |

## Validation

Run `scripts/test.sh` to verify correctness (7 assertions covering core, edge cases, and error handling).
