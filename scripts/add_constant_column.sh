#!/bin/bash

# Script to add a constant value column to a CSV file
# Usage: ./add_constant_column.sh <input_file> <output_file> <constant_value> [<header_name>]

set -e

if [ $# -lt 3 ]; then
    echo "Usage: $0 <input_file> <output_file> <constant_value> [<header_name>]"
    echo "Example: $0 input.csv output.csv \"VALUE\" \"NEW_COLUMN\""
    exit 1
fi

INPUT_FILE=$1
OUTPUT_FILE=$2
CONSTANT_VALUE=$3
HEADER_NAME=${4:-"CONSTANT"} # Default header name is "CONSTANT" if not provided

# Check if input file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' not found."
    exit 1
fi

# Check if the file is empty
if [ ! -s "$INPUT_FILE" ]; then
    echo "Error: Input file '$INPUT_FILE' is empty."
    exit 1
fi

# Create a temporary file
TMP_FILE=$(mktemp)

# Process the header first
head -1 "$INPUT_FILE" > "$TMP_FILE"
sed -i "" -e "s/$/,${HEADER_NAME}/" "$TMP_FILE"

# Process the rest of the file - add constant value to each line
tail -n +2 "$INPUT_FILE" | while IFS= read -r line; do
    echo "${line},${CONSTANT_VALUE}" >> "$TMP_FILE"
done

# Move the temporary file to the output file
mv "$TMP_FILE" "$OUTPUT_FILE"

echo "Added column '$HEADER_NAME' with value '$CONSTANT_VALUE' to $OUTPUT_FILE"
