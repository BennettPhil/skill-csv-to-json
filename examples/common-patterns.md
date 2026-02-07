# Common Patterns

> The most common ways to use csv-to-json in practice.

## Pattern 1: Custom Delimiter

When your data uses tabs or semicolons instead of commas.

```bash
./scripts/run.sh data.tsv --delimiter "\t"
```

Input (`data.tsv`):

```
product	price	quantity
Widget	9.99	100
Gadget	24.50	50
```

Output:

```json
[
  {"product": "Widget", "price": "9.99", "quantity": "100"},
  {"product": "Gadget", "price": "24.50", "quantity": "50"}
]
```

## Pattern 2: Nested Headers with Dot Notation

Flatten nested JSON structures from dot-notation headers.

```bash
./scripts/run.sh employees.csv
```

Input (`employees.csv`):

```csv
name,address.city,address.state,address.zip
Jane Doe,Portland,OR,97201
John Smith,Seattle,WA,98101
```

Output:

```json
[
  {"name": "Jane Doe", "address": {"city": "Portland", "state": "OR", "zip": "97201"}},
  {"name": "John Smith", "address": {"city": "Seattle", "state": "WA", "zip": "98101"}}
]
```

## Pattern 3: Quoted Fields with Commas

CSV fields containing commas, quotes, or newlines.

```bash
./scripts/run.sh contacts.csv
```

Input (`contacts.csv`):

```csv
name,note,city
"Smith, John","Said ""hello""",Portland
"Doe, Jane","Line 1",Seattle
```

Output:

```json
[
  {"name": "Smith, John", "note": "Said \"hello\"", "city": "Portland"},
  {"name": "Doe, Jane", "note": "Line 1", "city": "Seattle"}
]
```

## Pattern 4: Output to File

Save the result to a file instead of stdout.

```bash
./scripts/run.sh data.csv --output data.json
```

## Pattern 5: Pretty Print vs Compact

```bash
# Pretty printed (default)
./scripts/run.sh data.csv

# Compact single-line output
./scripts/run.sh data.csv --compact
```

Compact output:

```json
[{"name":"Alice","age":"30"},{"name":"Bob","age":"25"}]
```
