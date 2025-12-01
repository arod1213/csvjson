# CSVJSON

A command-line utility for serializing CSV/TSV files into readable JSON format.

## Overview

CSVJSON converts comma-separated values (CSV) and tab-separated values (TSV) files into JSON format, providing flexible options for output formatting and data processing.

## Features

-   Convert CSV/TSV files to JSON
-   Type definitions for JSON keys
-   Show shared keys given multiple files
-   Customizable delimiters for various file formats
-   Line-based processing with offset support
-   Multiple output formats (pretty-printed JSON or JSONL)

## Flags

### `-r`

```bash
# read type options
all | keys | types
```
Defaults to all

### `-r all`
```bash
# prints all key value pairs for all lines in csv
cat input.csv | csvjson -r all

# prints first set of key value pairs
cat input.csv | csvjson -r all -l 1

# prints only the 50th set of key value pairs
cat input.csv | csvjson -r all -l 1 -o 50
```

### `-r types`
```bash
# prints all possible types for each key value
cat input.csv | csvjson -r types
```

### `-r keys`
```bash
# finds all shared keys for all csvs in current directory
csvjson -r keys -f ./*.csv

# finds all keys which at least 5 files share in common
csvjson -r keys -f ./*.csv -l 5

# finds all keys
csvjson -r keys -f ./*.csv -l 1
```

### `-s`

Set the delimiter/separator for the input file.

**Examples:**

-   CSV: `-s ','`
-   TSV: `-s $'\t'`

bash

```bash
cat input.csv | csvjson -s ','
cat input.tsv | csvjson -s $'\t'
```

### `-l`

Set the total number of lines to read from the input file.

bash

```bash
# read only first 100 lines
cat input.csv | csvjson -l=100  
```

### `-o`

Set the offset for which line to start reading from.

bash

```bash
# skip first 10 lines
cat input.csv | csvjson -o=10
```

### `-m`

Output JSONL (JSON Lines) format instead of pretty-printed JSON. Each line contains a separate JSON object.

bash

```bash
# print minimized jsonl
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
    "languages": "Array of String",
    "age": "Int",
    "email": "String"
}
```
