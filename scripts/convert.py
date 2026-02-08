#!/usr/bin/env python3
"""CSV to JSON converter with type inference."""

import argparse
import csv
import json
import sys

def infer_type(value):
    if value == "":
        return None
    if value.lower() in ("true", "false"):
        return value.lower() == "true"
    try:
        if "." in value:
            return float(value)
        return int(value)
    except ValueError:
        return value

def main():
    parser = argparse.ArgumentParser(description="CSV to JSON")
    parser.add_argument("file", nargs="?")
    parser.add_argument("--delimiter", default=",")
    parser.add_argument("--jsonl", action="store_true")
    parser.add_argument("--no-infer", action="store_true", dest="no_infer")
    args = parser.parse_args()

    if args.file:
        fh = open(args.file, newline="")
    else:
        fh = sys.stdin

    reader = csv.DictReader(fh, delimiter=args.delimiter)
    rows = []
    for row in reader:
        obj = {}
        for k, v in row.items():
            if k is None:
                continue
            val = v if args.no_infer else infer_type(v)
            obj[k] = val
        rows.append(obj)

    if args.file:
        fh.close()

    if args.jsonl:
        for row in rows:
            print(json.dumps(row, ensure_ascii=False))
    else:
        print(json.dumps(rows, indent=2, ensure_ascii=False))

if __name__ == "__main__":
    main()
