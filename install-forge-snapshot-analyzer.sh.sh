#!/bin/bash

# Define some color codes
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RED="\033[1;31m"
RESET="\033[0m"

# Function to print stylish output
print_message() {
    echo -e "${BLUE}[${YELLOW}INFO${BLUE}]${RESET} ${GREEN}$1${RESET}"
}

# Directory to create
DIR_NAME="forge-snapshot-analyzer-scripts"

# Create the directory
if [[ -d "$DIR_NAME" ]]; then
    print_message "Directory $DIR_NAME already exists. Removing and recreating..."
    rm -rf "$DIR_NAME"
fi
mkdir "$DIR_NAME"
print_message "Directory $DIR_NAME created."

# Create and copy the scripts to the directory
SCRIPTS=("compare-gas-snapshots.sh" "filter-out-zero-gas-results.sh" "count-total-gas.sh" "analyze-gas-results.sh")

for script in "${SCRIPTS[@]}"; do
    touch "$DIR_NAME/$script"
    chmod +x "$DIR_NAME/$script"
    print_message "Created $DIR_NAME/$script."
done

# >>> START compare-gas-snapshots.sh <<<
cat > "$DIR_NAME/compare-gas-snapshots.sh" <<EOF
#!/bin/bash

# Output file name
OUTPUT_FILE="./forge-snapshot-analyzer-scripts/.snapshots-compared-results"

# Check for correct number of arguments
if [ "\$#" -ne 2 ]; then
    echo "Usage: \$0 <snapshot1_file> <snapshot2_file>"
    exit 1
fi

# Extract test names and gas values from each file
declare -A snapshot1
declare -A snapshot2

extract_gas() {
    local line=\$1
    if [[ \$line == *"(gas:"* ]]; then
        echo "\$line" | sed -n 's/.*gas: \([0-9]*\).*/\1/p'
    elif [[ \$line == *", μ:"* ]]; then
        echo "\$line" | sed -n 's/.*μ: \([0-9]*\).*/\1/p'
    else
        echo "0"
    fi
}

while IFS= read -r line || [[ -n "\$line" ]]; do
    testname=\$(echo "\$line" | cut -d '(' -f 1 | awk '{\$1=\$1};1')
    gasvalue=\$(extract_gas "\$line")
    snapshot1["\$testname"]=\$gasvalue
done < "\$1"

while IFS= read -r line || [[ -n "\$line" ]]; do
    testname=\$(echo "\$line" | cut -d '(' -f 1 | awk '{\$1=\$1};1')
    gasvalue=\$(extract_gas "\$line")
    snapshot2["\$testname"]=\$gasvalue
done < "\$2"

# Compare and save differences to the output file
{
    echo "Test Name | Snapshot 1 Gas | Snapshot 2 Gas | Difference"
    echo "---------------------------------------------------------"
    for testname in "\${!snapshot1[@]}"; do
        if [[ \${snapshot2["\$testname"]} ]]; then
            diff=\$(( snapshot2["\$testname"] - snapshot1["\$testname"] ))
            echo "\$testname | \${snapshot1["\$testname"]} | \${snapshot2["\$testname"]} | \$diff"
        fi
    done
} > "\$OUTPUT_FILE"

echo "Results saved in \$OUTPUT_FILE"
EOF
# >>> END compare-gas-snapshots.sh <<<

# >>> START filter-out-zero-gas-results.sh <<<
cat > "$DIR_NAME/filter-out-zero-gas-results.sh" <<EOF
#!/bin/bash

# Check for input file
if [ "\$#" -ne 1 ]; then
    echo "Usage: \$0 <input_file>"
    exit 1
fi

input_file="\$1"

# Check if input file exists
if [ ! -f "\$input_file" ]; then
    echo "Error: File \$input_file not found!"
    exit 1
fi

# Filter out rows where the difference is 0 and save to .gas-snapshot-filtered
awk -F ' \\| ' 'NR == 1 || \$NF != 0' "\$input_file" > ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered

echo "Filtered results saved to ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered"
EOF
# >>> END filter-out-zero-gas-results.sh <<<

# >>> START count-total-gas.sh <<<
cat > "$DIR_NAME/count-total-gas.sh" <<EOF
#!/bin/bash

# Check if file path is provided
if [[ ! -f \$1 ]]; then
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
    num1=\$(echo "\$line" | awk -F '|' '{print \$2}' | tr -d ' ' | grep -E '^[0-9]+\$')
    num2=\$(echo "\$line" | awk -F '|' '{print \$3}' | tr -d ' ' | grep -E '^[0-9]+\$')
    num3=\$(echo "\$line" | awk -F '|' '{print \$4}' | tr -d ' ' | grep -E '^[-0-9]+\$')

    if [[ \$num1 ]]; then
        ((sum1+=num1))
    fi

    if [[ \$num2 ]]; then
        ((sum2+=num2))
    fi

    if [[ \$num3 ]]; then
        ((sum3+=num3))
    fi
done < "\$1"

# Print the results
echo "Total for Snapshot 1 Gas: \$sum1"
echo "Total for Snapshot 2 Gas: \$sum2"
echo "Total Difference: \$sum3"
EOF
# >>> END count-total-gas.sh <<<

# >>> START analyze-gas-results.sh <<<
cat > "$DIR_NAME/analyze-gas-results.sh" <<EOF
#!/bin/bash

BOLD="\033[1m"
RED="\033[1;31m"
GREEN="\033[1;32m"
LIGHT_BLUE="\033[1;34m"
RESET="\033[0m"

# Check for correct number of arguments
if [ "\$#" -ne 1 ]; then
    echo "Usage: \$0 <results_file>"
    exit 1
fi

# Initialize values for computation
total_gas_saved=0
total_gas_original=0

# Skip the header and start reading the results
while IFS="|" read -r testname snapshot1 snapshot2 diff; do
    # Removing unwanted spaces from each value
    snapshot1=\$(echo \$snapshot1 | xargs)
    snapshot2=\$(echo \$snapshot2 | xargs)
    diff=\$(echo \$diff | xargs)
    
    # Computing cumulative sum for total gas saved and total gas from the original code
    total_gas_saved=\$((total_gas_saved + diff))
    total_gas_original=\$((total_gas_original + snapshot2))
done < <(tail -n +3 "\$1")

# Handle the case when total_gas_original is 0
if [ "\$total_gas_original" -eq 0 ]; then
    echo "Total Gas Original is zero, cannot compute percentage"
    exit 1
fi

# Calculate the percentage
percentage_saved=\$(echo "scale=4; (\$total_gas_saved / \$total_gas_original) * 100" | bc)

# Decide color based on total_gas_saved
if [ "\$total_gas_saved" -gt 0 ]; then
    COLOR=\$GREEN
elif [ "\$total_gas_saved" -lt 0 ]; then
    COLOR=\$RED
else
    COLOR=\$LIGHT_BLUE
fi

# Display results in the chosen color
echo -e "Total Gas Saved: \${COLOR}\$total_gas_saved\${RESET}"
echo -e "Percentage Saved on Snapshot 2 Gas: \${COLOR}\$percentage_saved%\${RESET}"
EOF
# >>> END analyze-gas-results.sh <<<

# Create the main script in the current directory
MAIN_SCRIPT="forge-snapshots-analyzer.sh"

cat > "$MAIN_SCRIPT" <<EOL
#!/bin/bash

# Define some color codes
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
BLUE="\033[1;34m"
RESET="\033[0m"

# Function to print stylish output
print_message() {
    echo -e "${BLUE}[${YELLOW}INFO${BLUE}]${RESET} ${GREEN}\$1${RESET}"
}

# Check for correct number of arguments
if [ "\$#" -ne 2 ]; then
    echo -e "${RED}Usage: \$0 <snapshot1_file> <snapshot2_file>${RESET}"
    exit 1
fi

snapshot1_file="\$1"
snapshot2_file="\$2"

# 1. Compare gas snapshots
print_message "Comparing gas snapshots..."
./$DIR_NAME/compare-gas-snapshots.sh "\$snapshot1_file" "\$snapshot2_file"

# 2. Filter out zero gas results
print_message "Filtering out zero gas results..."
./$DIR_NAME/filter-out-zero-gas-results.sh ./forge-snapshot-analyzer-scripts/.snapshots-compared-results
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"

# 3. Count total gas
echo " "
print_message "Counting total gas consumed..."
./$DIR_NAME/count-total-gas.sh ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered
echo " "
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"

# 4. Analyze gas results
echo " "
print_message "Analyzing gas results..."
./$DIR_NAME/analyze-gas-results.sh ./forge-snapshot-analyzer-scripts/.snapshots-compared-filtered
echo " "
echo "+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-"

print_message "All tasks completed!"
EOL

chmod +x "$MAIN_SCRIPT"
print_message "Main script $MAIN_SCRIPT created and made executable."

print_message "Installation complete."
