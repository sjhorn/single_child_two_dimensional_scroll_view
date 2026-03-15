#!/usr/bin/env bash
# scripts/ci/flutter_test.sh
#
# Run flutter test, capture verbose output to /tmp, print summary to stdout.
# Usage:
#   ./scripts/ci/flutter_test.sh                        # summary only
#   ./scripts/ci/flutter_test.sh --verbose              # summary + full output
#   ./scripts/ci/flutter_test.sh test/src/model/        # specific path
#   ./scripts/ci/flutter_test.sh --coverage             # with coverage
#   ./scripts/ci/flutter_test.sh --update-goldens       # update goldens
#   ./scripts/ci/flutter_test.sh --filter "DocumentSelection"
#
# Output files written:
#   /tmp/${PREFIX}_test_full.txt    — complete flutter test output
#   /tmp/${PREFIX}_test_fail.txt    — failing tests only
#   /tmp/${PREFIX}_test_summary.txt — pass/fail/skip counts + duration

set -uo pipefail
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

VERBOSE=false
FLUTTER_ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--verbose" ]; then
    VERBOSE=true
  else
    FLUTTER_ARGS+=("$arg")
  fi
done

LOGFILE="/tmp/${PREFIX}_test_full.txt"
FAILFILE="/tmp/${PREFIX}_test_fail.txt"
SUMMARYFILE="/tmp/${PREFIX}_test_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

if [ ${#FLUTTER_ARGS[@]} -eq 0 ]; then
  FLUTTER_ARGS=("test")
fi

echo "[$TIMESTAMP] flutter test ${FLUTTER_ARGS[*]}" >"$LOGFILE"

START_EPOCH=$(date +%s)
flutter test "${FLUTTER_ARGS[@]}" >>"$LOGFILE" 2>&1
TEST_EXIT=$?
END_EPOCH=$(date +%s)
DURATION=$((END_EPOCH - START_EPOCH))

# Extract failures into their own file (strip \r from flutter test progress output)
tr '\r' '\n' <"$LOGFILE" | \
  grep -E "^\s*(FAILED|✗|══+|Error:|Unhandled exception|Expected|Actual)" \
  >"$FAILFILE" 2>/dev/null || true

# Parse counts from the last progress line, e.g. "00:04 +244 ~2 -3: ..."
# Flutter test lines look like: "00:03 +244: All tests passed!"
PASSED=0
FAILED=0
SKIPPED=0

# Flutter test uses \r for progress — strip it before grepping
FINAL_LINE=$(tr '\r' '\n' <"$LOGFILE" | grep -E '^[0-9][0-9]:[0-9][0-9] ' | tail -1)
if [ -n "$FINAL_LINE" ]; then
  p=$(echo "$FINAL_LINE" | grep -oE '\+[0-9]+' | head -1 | tr -d '+')
  f=$(echo "$FINAL_LINE" | grep -oE ' -[0-9]+' | head -1 | tr -d ' -')
  s=$(echo "$FINAL_LINE" | grep -oE '~[0-9]+' | head -1 | tr -d '~')
  PASSED=${p:-0}
  FAILED=${f:-0}
  SKIPPED=${s:-0}
fi

# Build human-readable summary
{
  echo "=== flutter test summary ==="
  echo "Timestamp : $TIMESTAMP"
  echo "Duration  : ${DURATION}s"
  echo "Args      : ${FLUTTER_ARGS[*]}"
  echo ""
  echo "Passed  : $PASSED"
  echo "Failed  : $FAILED"
  echo "Skipped : $SKIPPED"
  echo "Exit    : $TEST_EXIT"
  echo ""
  if [ -s "$FAILFILE" ]; then
    echo "--- Failures ---"
    cat "$FAILFILE"
  else
    echo "All tests passed."
  fi
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "--- Full output ---"
    cat "$LOGFILE"
  fi
} | tee "$SUMMARYFILE"

exit "$TEST_EXIT"
