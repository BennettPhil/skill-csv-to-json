# Basic Example

> Convert a simple CSV file to JSON.

## What You Will Learn

In this example, you will see the simplest way to use `csv-to-json`. By the end, you will understand:

- How to convert a CSV file to JSON
- What output format to expect
- How headers become JSON keys

## Step 1: Run the Skill

Given a file `users.csv`:

```csv
name,email,age
Alice,alice@example.com,30
Bob,bob@example.com,25
```

Run:

```bash
./scripts/run.sh users.csv
```

## Step 2: See the Output

Expected output:

```json
[
  {"name": "Alice", "email": "alice@example.com", "age": "30"},
  {"name": "Bob", "email": "bob@example.com", "age": "25"}
]
```

## Step 3: Try a Variation

Pipe from stdin:

```bash
echo "name,score
Charlie,95" | ./scripts/run.sh --stdin
```

Expected output:

```json
[
  {"name": "Charlie", "score": "95"}
]
```

## What Just Happened

The tool read the first line as column headers, then converted each subsequent row into a JSON object using those headers as keys. The result is a JSON array of objects.

## Next Steps

- For more usage patterns, see [Common Patterns](./common-patterns.md)
- For advanced features, see [Advanced Usage](./advanced-usage.md)
- For the full reference, see the [SKILL.md](../SKILL.md)
