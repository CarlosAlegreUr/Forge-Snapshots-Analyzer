#!/bin/bash

BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
LIGHT_BLUE="\033[1;34m"
RESET="\033[0m"

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

# Decide color based on total_gas_saved
if [ "$total_gas_saved" -gt 0 ]; then
    COLOR=$GREEN
elif [ "$total_gas_saved" -lt 0 ]; then
    COLOR=$RED
else
    COLOR=$LIGHT_BLUE
fi

# Display results in the chosen color
echo -e "Total Gas Saved: ${COLOR}$total_gas_saved${RESET}"
echo -e "Percentage Saved on Snapshot 2 Gas: ${COLOR}$percentage_saved%${RESET}"
