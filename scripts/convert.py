#!/usr/bin/env python3
"""Convert CSV to JSON with support for custom delimiters, nested headers, and streaming."""

import argparse
import csv
import json
import sys


def infer_type(value):
    """Try to convert a string to a native Python type."""
    if value == "":
        return value
    if value.lower() == "true":
        return True
    if value.lower() == "false":
        return False
    try:
        return int(value)
    except ValueError:
        pass
    try:
        return float(value)
    except ValueError:
        pass
    return value


def nest_object(headers, values, do_infer):
    """Create a nested object from dot-notation headers."""
    obj = {}
    for header, value in zip(headers, values):
        val = infer_type(value) if do_infer else value
        parts = header.split(".")
        current = obj
        for i, part in enumerate(parts):
            if i == len(parts) - 1:
                current[part] = val
            else:
                if part not in current:
                    current[part] = {}
                current = current[part]
    return obj


def process_csv(reader, headers, args):
    """Process CSV rows and yield JSON objects."""
    has_nested = any("." in h for h in headers)

    for row in reader:
        # Pad row if fewer columns than headers
        while len(row) < len(headers):
            row.append("")
        # Truncate row if more columns than headers
        row = row[: len(headers)]

        if has_nested:
            obj = nest_object(headers, row, args.infer_types)
        else:
            obj = {}
            for header, value in zip(headers, row):
                obj[header] = infer_type(value) if args.infer_types else value

        yield obj


def main():
    parser = argparse.ArgumentParser(description="Convert CSV to JSON")
    parser.add_argument("input", nargs="?", default=None, help="Input CSV file")
    parser.add_argument("--stdin", action="store_true", help="Read from stdin")
    parser.add_argument("--delimiter", default=",", help="Field delimiter")
    parser.add_argument("--output", default="", help="Output file path")
    parser.add_argument("--compact", action="store_true", help="Compact JSON")
    parser.add_argument("--ndjson", action="store_true", help="NDJSON output")
    parser.add_argument("--infer-types", action="store_true", help="Infer types")
    parser.add_argument("--skip-lines", type=int, default=0, help="Lines to skip")
    args = parser.parse_args()

    # Handle delimiter escape sequences
    delimiter = args.delimiter
    if delimiter == "\\t":
        delimiter = "\t"

    # Open input
    if args.stdin or args.input is None:
        infile = sys.stdin
    else:
        infile = open(args.input, "r", newline="")

    try:
        # Skip lines
        for _ in range(args.skip_lines):
            infile.readline()

        reader = csv.reader(infile, delimiter=delimiter)

        # Read headers
        try:
            headers = next(reader)
        except StopIteration:
            # Empty input
            if args.ndjson:
                result = ""
            else:
                result = "[]\n"
            if args.output:
                with open(args.output, "w") as f:
                    f.write(result)
            else:
                sys.stdout.write(result)
            return

        # Strip whitespace from headers
        headers = [h.strip() for h in headers]

        if not any(h for h in headers):
            # All-empty headers
            if args.ndjson:
                result = ""
            else:
                result = "[]\n"
            if args.output:
                with open(args.output, "w") as f:
                    f.write(result)
            else:
                sys.stdout.write(result)
            return

        # Process and output
        outfile = open(args.output, "w") if args.output else sys.stdout

        try:
            if args.ndjson:
                for obj in process_csv(reader, headers, args):
                    outfile.write(json.dumps(obj, ensure_ascii=False) + "\n")
            else:
                results = list(process_csv(reader, headers, args))
                indent = None if args.compact else 2
                separators = (",", ":") if args.compact else None
                outfile.write(
                    json.dumps(results, indent=indent, separators=separators, ensure_ascii=False)
                    + "\n"
                )
        finally:
            if args.output:
                outfile.close()
    finally:
        if not (args.stdin or args.input is None):
            infile.close()


if __name__ == "__main__":
    main()
