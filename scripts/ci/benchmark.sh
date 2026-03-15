#!/usr/bin/env bash
# scripts/ci/benchmark.sh
#
# Run micro-benchmarks and write results to benchmark/results/.
#
# Usage:
#   ./scripts/ci/benchmark.sh                    # run all benchmarks
#   ./scripts/ci/benchmark.sh document_model     # run specific benchmark
#
# Output files written:
#   benchmark/results/latest.json  — combined results from all benchmarks
#   /tmp/${PREFIX}_benchmark_full.txt     — complete benchmark output
#
# Note: Benchmarks use BenchmarkBase.report() in main() rather than test()
# calls, so flutter test reports "No tests ran." — this is expected and is
# not treated as a failure.

set -uo pipefail
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

LOGFILE="/tmp/${PREFIX}_benchmark_full.txt"
RESULTS_DIR="benchmark/results"
TIMESTAMP=$(date +%Y-%m-%dT%H:%M:%S)

mkdir -p "$RESULTS_DIR"

# Collect benchmark files to run.
if [ $# -gt 0 ]; then
  FILES=()
  for name in "$@"; do
    FILES+=("benchmark/${name}_benchmark.dart")
  done
else
  FILES=(benchmark/*_benchmark.dart)
fi

echo "=== benchmark run ===" | tee "$LOGFILE"
echo "Timestamp : $TIMESTAMP" | tee -a "$LOGFILE"
echo "Files     : ${FILES[*]}" | tee -a "$LOGFILE"
echo "" | tee -a "$LOGFILE"

EXIT=0

for file in "${FILES[@]}"; do
  if [ ! -f "$file" ]; then
    echo "WARNING: $file not found, skipping" | tee -a "$LOGFILE"
    continue
  fi

  echo "--- Running $file ---" | tee -a "$LOGFILE"
  OUTPUT=$(flutter test --no-pub "$file" 2>&1) || true
  echo "$OUTPUT" | tee -a "$LOGFILE"

  # "No tests ran" is expected (benchmarks use main() not test()).
  # Treat as failure only if there's a real compilation or runtime error.
  if echo "$OUTPUT" | grep -q "Error:"; then
    echo "FAILED: $file (compilation/runtime error)" | tee -a "$LOGFILE"
    EXIT=1
  elif echo "$OUTPUT" | grep -q "EXCEPTION CAUGHT"; then
    echo "FAILED: $file (exception thrown)" | tee -a "$LOGFILE"
    EXIT=1
  fi
  echo "" | tee -a "$LOGFILE"
done

# Write a simple JSON results file with timestamp.
cat > "$RESULTS_DIR/latest.json" <<ENDJSON
{
  "timestamp": "$TIMESTAMP",
  "results": "see /tmp/${PREFIX}_benchmark_full.txt for detailed output"
}
ENDJSON

echo "=== benchmark summary ===" | tee -a "$LOGFILE"
echo "Timestamp : $TIMESTAMP" | tee -a "$LOGFILE"
echo "Results   : $RESULTS_DIR/latest.json" | tee -a "$LOGFILE"
echo "Exit      : $EXIT" | tee -a "$LOGFILE"

exit $EXIT
