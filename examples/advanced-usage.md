# Advanced Usage

> Power-user scenarios showing the full capabilities of csv-to-json.

## Combining Multiple Options

Custom delimiter with nested headers and compact output:

```bash
./scripts/run.sh data.tsv --delimiter "\t" --compact
```

## Streaming Large Files

For files too large to fit in memory, use line-by-line JSON output (one JSON object per line, aka NDJSON):

```bash
./scripts/run.sh large-file.csv --ndjson
```

Output (one object per line, no wrapping array):

```
{"name":"Alice","email":"alice@example.com","age":"30"}
{"name":"Bob","email":"bob@example.com","age":"25"}
```

This can be piped to tools like `jq`:

```bash
./scripts/run.sh large-file.csv --ndjson | jq 'select(.age | tonumber > 25)'
```

## Type Inference

By default all values are strings. Use `--infer-types` to convert numbers and booleans:

```bash
./scripts/run.sh data.csv --infer-types
```

Input:

```csv
name,age,active
Alice,30,true
Bob,25,false
```

Output:

```json
[
  {"name": "Alice", "age": 30, "active": true},
  {"name": "Bob", "age": 25, "active": false}
]
```

## Custom Header Row

Skip lines or use a specific row as headers:

```bash
./scripts/run.sh report.csv --skip-lines 2
```

This skips the first 2 lines before treating the next line as headers.
