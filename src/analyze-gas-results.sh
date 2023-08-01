#!/bin/bash

# Check for correct number of arguments
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <results_file>"
    exit 1
fi

# Initialize values for computation
total_gas_saved=0
total_gas_original=0

# Skip the header and start reading the results
while IFS="|" read -r testname snapshot1 snapshot2 diff; do
    # Removing unwanted spaces from each value
    snapshot1=$(echo $snapshot1 | xargs)
    snapshot2=$(echo $snapshot2 | xargs)
    diff=$(echo $diff | xargs)
    
    # Computing cumulative sum for total gas saved and total gas from the original code
    total_gas_saved=$((total_gas_saved + diff))
    total_gas_original=$((total_gas_original + snapshot2))
done < <(tail -n +3 "$1")

# Handle the case when total_gas_original is 0
if [ "$total_gas_original" -eq 0 ]; then
    echo "Total Gas Original is zero, cannot compute percentage"
    exit 1
fi

# Calculate the percentage
percentage_saved=$(echo "scale=4; ($total_gas_saved / $total_gas_original) * 100" | bc)

# Display results
echo "Total Gas Saved: $total_gas_saved"
echo "Percentage Saved on Original Gas: $percentage_saved%"
