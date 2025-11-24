# CSVJSON

A command-line utility for serializing CSV/TSV files into readable JSON format.

## Overview

CSVJSON converts comma-separated values (CSV) and tab-separated values (TSV) files into JSON format, providing flexible options for output formatting and data processing.

## Features

-   Convert CSV/TSV files to JSON
-   Optional type definitions for JSON keys
-   Customizable delimiters for various file formats
-   Line-based processing with offset support
-   Multiple output formats (pretty-printed JSON or JSONL)

## Flags

### `-t` / `-T`

Display type definitions for each key in the serialized JSON object.

bash

```bash
cat input.csv | csvjson -t
```

### `-s` / `-S`

Set the delimiter/separator for the input file.

**Examples:**

-   CSV: `-s=','`
-   TSV: `-s=$'\t'`

bash

```bash
cat input.csv | csvjson -s=','
cat input.tsv | csvjson -s=$'\t'
```

### `-l` / `-L`

Set the total number of lines to read from the input file.

bash

```bash
cat input.csv | csvjson -l=100  # Read only first 100 lines
```

### `-o` / `-O`

Set the offset for which line to start reading from.

bash

```bash
cat input.csv | csvjson -o=10  # Skip first 10 lines
```

### `-m` / `-M`

Output JSONL (JSON Lines) format instead of pretty-printed JSON. Each line contains a separate JSON object.

bash

```bash
cat input.csv | csvjson -m
```

## Usage Examples

### Basic CSV conversion

bash

```bash
cat input.csv | csvjson
```

### Convert TSV with type definitions

bash

```bash
input.tsv | csvjson -t -s=$'\t'
```

### Process specific range with JSONL output

bash

```bash
cat data.csv | csvjson -o=50 -l=100 -m  # Lines 50-150 as JSONL
```

## Output Formats

### Pretty-printed JSON (default)
```json
[
  {
    "name": "John Doe",
    "favorite_color": null,
    "languages": ["French", "English"],
    "age": 30,
    "email": "john@example.com"
  },
  {
    "name": "Jane Smith",
    "favorite_color": "blue",
    "languages": ["English"],
    "age": 25,
    "email": "jane@example.com"
  }
]
```

### JSONL format (`-m` flag)
```json
{"name":"John Doe","favorite_color":null,"languages":["French","English"],"age":30,"email":"john@example.com"}
{"name":"Jane Smith","favorite_color":"blue","languages":["English"],"age":25,"email":"jane@example.com"}
```

### Pretty-printed JSON with types (`-t` flag)
```json
{
    "name": "String",
    "favorite_color": "Null | String",
    "languages": "Srray of String",
    "age": "Int",
    "email": "String"
}
```
