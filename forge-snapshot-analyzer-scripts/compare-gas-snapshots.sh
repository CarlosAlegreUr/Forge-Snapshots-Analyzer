#!/bin/bash

# Output file name
OUTPUT_FILE="./forge-snapshot-analyzer-scripts/.snapshots-compared-results"

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <snapshot1_file> <snapshot2_file>"
    exit 1
fi

# Extract test names and gas values from each file
declare -A snapshot1
declare -A snapshot2

extract_gas() {
    local line=$1
    if [[ $line == *"(gas:"* ]]; then
        echo "$line" | sed -n 's/.*gas: \([0-9]*\).*/\1/p'
    elif [[ $line == *", μ:"* ]]; then
        echo "$line" | sed -n 's/.*μ: \([0-9]*\).*/\1/p'
    else
        echo "0"
    fi
}

while IFS= read -r line || [[ -n "$line" ]]; do
    testname=$(echo "$line" | cut -d '(' -f 1 | awk '{$1=$1};1')
    gasvalue=$(extract_gas "$line")
    snapshot1["$testname"]=$gasvalue
done < "$1"

while IFS= read -r line || [[ -n "$line" ]]; do
    testname=$(echo "$line" | cut -d '(' -f 1 | awk '{$1=$1};1')
    gasvalue=$(extract_gas "$line")
    snapshot2["$testname"]=$gasvalue
done < "$2"

# Compare and save differences to the output file
{
    echo "Test Name | Snapshot 1 Gas | Snapshot 2 Gas | Difference"
    echo "---------------------------------------------------------"
    for testname in "${!snapshot1[@]}"; do
        if [[ ${snapshot2["$testname"]} ]]; then
            diff=$(( snapshot2["$testname"] - snapshot1["$testname"] ))
            echo "$testname | ${snapshot1["$testname"]} | ${snapshot2["$testname"]} | $diff"
        fi
    done
} > "$OUTPUT_FILE"

echo "Results saved in $OUTPUT_FILE"
