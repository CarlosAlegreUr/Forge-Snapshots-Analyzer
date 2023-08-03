#!/bin/bash

# Define some color codes
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

# Function to print stylish output
print_message() {
    echo -e "\033[1;34m[\033[1;33mINFO\033[1;34m]\033[0m \033[1;32m$1\033[0m"
}

# Check for correct number of arguments
if [ "$#" -ne 2 ]; then
    echo -e "\033[1;31mUsage: $0 <snapshot1_file> <snapshot2_file>\033[0m"
    exit 1
fi

snapshot1_file="$1"
snapshot2_file="$2"

# 1. Compare gas snapshots
print_message "Comparing gas snapshots..."
./forge-snapshot-analyzer-scripts/compare-gas-snapshots.sh "$snapshot1_file" "$snapshot2_file"

# 2. Filter out zero gas results
print_message "Filtering out zero gas results..."
./forge-snapshot-analyzer-scripts/filter-out-zero-gas-results.sh ./forge-snapshot-analyzer-scripts/.snapshots-compared-results
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"

# 3. Count total gas
echo " "
print_message "Counting total gas consumed..."
./forge-snapshot-analyzer-scripts/count-total-gas.sh ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered
echo " "
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"

# 4. Analyze gas results
echo " "
print_message "Analyzing gas results..."
./forge-snapshot-analyzer-scripts/analyze-gas-results.sh ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered
echo " "
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"

print_message "All tasks completed!"
