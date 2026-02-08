# csv-to-json

Convert CSV files to JSON with support for custom delimiters, quoted fields, and nested headers via dot notation.

## Quick Start

```bash
echo 'name,age
Alice,30' | ./scripts/run.sh
```

## Prerequisites

- Bash 4+
- awk (standard on all Unix systems)
- python3 (optional, for JSON validation)

## Usage

```bash
# Convert a CSV file
./scripts/run.sh data.csv

# Tab-delimited input
./scripts/run.sh --delimiter '\t' data.tsv

# Nested headers via dot notation
echo 'user.name,user.email
Alice,alice@example.com' | ./scripts/run.sh

# Pretty-print
./scripts/run.sh --pretty data.csv
```

See [SKILL.md](SKILL.md) for full contract and options.
