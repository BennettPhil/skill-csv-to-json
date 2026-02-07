---
name: csv-to-json
description: Convert CSV files to JSON with support for custom delimiters, nested headers, quoted fields, and streaming
version: 0.1.0
license: Apache-2.0
---

# CSV to JSON

## Purpose

A robust CSV-to-JSON transformer that handles edge cases gracefully. It supports custom delimiters, quoted fields with embedded commas and quotes, nested headers via dot notation, type inference, and streaming output (NDJSON) for large files.

## See It in Action

Start with [examples/basic-example.md](examples/basic-example.md) to see the simplest usage.

## Examples Index

- **[basic-example.md](examples/basic-example.md)** — Convert a simple CSV file to a JSON array
- **[common-patterns.md](examples/common-patterns.md)** — Custom delimiters, nested headers, quoted fields, file output, compact mode
- **[advanced-usage.md](examples/advanced-usage.md)** — NDJSON streaming, type inference, skipping header lines, combining options
- **[edge-cases.md](examples/edge-cases.md)** — Empty input, missing fields, extra columns, file not found

## Reference

| Option | Default | Description |
|--------|---------|-------------|
| `<file>` | — | Input CSV file path (positional) |
| `--stdin` | false | Read from stdin instead of a file |
| `--delimiter <char>` | `,` | Field delimiter character |
| `--output <path>` | stdout | Write output to a file |
| `--compact` | false | Compact single-line JSON output |
| `--ndjson` | false | Output one JSON object per line (newline-delimited) |
| `--infer-types` | false | Convert numeric and boolean strings to native types |
| `--skip-lines <n>` | 0 | Skip n lines before reading headers |
| `--help` | — | Show usage information |

## Installation

Requires Python 3.7+. No additional dependencies needed.
