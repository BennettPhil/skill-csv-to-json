# Edge Cases

> How csv-to-json handles unusual situations.

## Empty Input

```bash
echo "" | ./scripts/run.sh --stdin
```

Output:

```json
[]
```

## Header Only (No Data Rows)

```bash
echo "name,age" | ./scripts/run.sh --stdin
```

Output:

```json
[]
```

## Empty Fields

Input:

```csv
name,email,phone
Alice,,555-0100
,bob@example.com,
```

Output:

```json
[
  {"name": "Alice", "email": "", "phone": "555-0100"},
  {"name": "", "email": "bob@example.com", "phone": ""}
]
```

## Rows with Fewer Columns Than Headers

Input:

```csv
a,b,c
1,2
3
```

Output:

```json
[
  {"a": "1", "b": "2", "c": ""},
  {"a": "3", "b": "", "c": ""}
]
```

## Rows with More Columns Than Headers

Extra columns are ignored:

Input:

```csv
a,b
1,2,3
4,5,6,7
```

Output:

```json
[
  {"a": "1", "b": "2"},
  {"a": "4", "b": "5"}
]
```

## File Not Found

```bash
./scripts/run.sh nonexistent.csv
```

Output (stderr, exit code 1):

```
Error: File not found: nonexistent.csv
```
