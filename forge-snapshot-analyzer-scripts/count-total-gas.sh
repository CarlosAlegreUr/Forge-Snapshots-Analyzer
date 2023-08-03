#!/bin/bash

# Check if file path is provided
if [[ ! -f $1 ]]; then
    echo "Please provide a valid file path."
    exit 1
fi

# Initialize sums
sum1=0
sum2=0
sum3=0

# Read the file line by line
while IFS= read -r line; do
    # Extract the numbers using awk and update the sums
    num1=$(echo "$line" | awk -F '|' '{print $2}' | tr -d ' ' | grep -E '^[0-9]+$')
    num2=$(echo "$line" | awk -F '|' '{print $3}' | tr -d ' ' | grep -E '^[0-9]+$')
    num3=$(echo "$line" | awk -F '|' '{print $4}' | tr -d ' ' | grep -E '^[-0-9]+$')

    if [[ $num1 ]]; then
        ((sum1+=num1))
    fi

    if [[ $num2 ]]; then
        ((sum2+=num2))
    fi

    if [[ $num3 ]]; then
        ((sum3+=num3))
    fi
done < "$1"

# Print the results
echo "Total for Snapshot 1 Gas: $sum1"
echo "Total for Snapshot 2 Gas: $sum2"
echo "Total Difference: $sum3"
