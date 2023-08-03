#!/bin/bash

# Check for input file
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

input_file="$1"

# Check if input file exists
if [ ! -f "$input_file" ]; then
    echo "Error: File $input_file not found!"
    exit 1
fi

# Filter out rows where the difference is 0 and save to .gas-snapshot-filtered
awk -F ' \| ' 'NR == 1 || $NF != 0' "$input_file" > ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered

echo "Filtered results saved to ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered"
