# Validation Guide

## Quick Smoke Test

```bash
echo 'name,age
Alice,30
Bob,25' | ./scripts/run.sh
```

Expected: `[{"name":"Alice","age":"30"},{"name":"Bob","age":"25"}]`

## Fallback Behavior

- If input is empty, output an empty JSON array `[]`
- If input has only a header row, output an empty JSON array `[]`
- If a row has fewer columns than the header, missing fields are set to null
- If a row has more columns than the header, extra fields are silently dropped
- If --delimiter is not provided, assume comma
