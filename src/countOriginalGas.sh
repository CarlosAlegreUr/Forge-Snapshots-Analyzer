#!/bin/bash

# Check if an argument is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <file_location>"
    exit 1
fi

file_location=$1

# Extract the values and sum them using awk
awk -F"|" '{if(NR>2) sum += $3} END {print sum}' "$file_location" | sed 's/ //g'

