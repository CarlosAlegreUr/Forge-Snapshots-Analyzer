# Forge Snapshots Analyzer 🧠

Forge Snapshots Analyzer is a bash script designed to compare and analyze snapshots made with `forge snapshot`. Currently, it supports the comparison of two gas snapshots.

It calculates:

- **Total gas saved**.
- **% of gas saved** compared to the original unoptimized code.

---

## Installation 📦

1. Ensure the `install-forge-snapshot-analyzer.sh` is in the same directory as your snapshots.

2. Grant execution permissions:

   ```bash
   chmod +x install-forge-snapshot-analyzer.sh
   ```

3. Execute the installation script:

   ```bash
   ./install-forge-snapshot-analyzer.sh
   ```

   ***

## Usage 🚀

After installation, you'll find a new bash script `forge-snapshots-analyzer.sh` in your directory with execution permissions pre-set. To get the best out of it:

> 📓 **Note**: When executing, make the snapshot of the optimized code be the first argument and the snapshot from the non-optimized the second argument.

Execute:

```bash
./forge-snapshots-analyzer.sh snapshot-optimized snapshot-non-optimized
```

Additionally, you'll notice a new directory named `./forge-snapshot-analyzer-scripts`. This contains all the auxiliary bash scripts that coordinate to analyze your snapshots.

---

## Snapshots examples in this repo 📸

In this repo, there are a few snapshots examples so you can clone the repo and see how the script functions:

- ⭐ `.gas-snapshot`: Original snapshot.
- ⭐ `.gas-snapshot-optimized`: Snapshot with improved gas consumption.
- ⭐ `.gas-snapshot-bad-opt`: Snapshot where gas consumption did not improve.
- ⭐ `.gas-snapshot-equal-opt`: Snapshot where individual test consumption changed, but net result was unchanged.

---

## Internal Workings of Bash Scripts 🛠️

<details>
  <summary>🔧 compare-gas-snapshots.sh</summary>

#### _**`compare-gas-snapshots.sh`**_

it goes row-by-row in a snapshot, comparing the `gas(number)` value with its counterpart in the second snapshot file. When a fuzz test is found, it extracts the value from the `μ:Number`. If an invariant test is detected, it defaults the gas consumption to 0 since `forge` currently doesn't offer gas metrics for such tests.

The results are saved in a `.snapshots-compared-results` file.

</details>

<details>
  <summary>🔧 filter-out-zero-gas-results.sh</summary>

#### _**`filter-out-zero-gas-results.sh`**_

This script checks the output file from `compare-gas-snapshots.sh`. If there's no difference in gas values between snapshots (i.e., the difference is 0), such results get filtered out. The processed file is named `.snapshots-compared-filtered`.

</details>

<details>
  <summary>🔧 count-total-gas.sh</summary>

#### _**`count-total-gas.sh`**_

It counts and displays the total gas consumption for both snapshots (`snapshot1` and `snapshot2`). It also shows the difference in gas (saved). All this derived from the `filter-out-zero-gas-results` output file.

</details>

<details>
  <summary>🔧 analyze-gas-results.sh</summary>

#### _**`analyze-gas-results.sh`**_

It operates on the file `filter-out-zero-gas-results`. It calculates:

- Cumulative sum of the last column (gas saved or not in each test).
- Cumulative sum of the penultimate column (original gas consumption).
- Percentage representation: `(gasSaved / originalConsumption) * 100`.

It then displays the total saved gas and its percentage against the original gas consumption.

</details>

---
