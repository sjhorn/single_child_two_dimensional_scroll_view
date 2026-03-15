#!/usr/bin/env bash
# scripts/ci/dart_format.sh
#
# Check or apply dart format with line-length 100.
# Verbose output captured to /tmp, summary printed to stdout.
# Usage:
#   ./scripts/ci/dart_format.sh check              # summary only (default)
#   ./scripts/ci/dart_format.sh fix                # apply formatting
#   ./scripts/ci/dart_format.sh check --verbose    # summary + full output
#   ./scripts/ci/dart_format.sh check lib/         # check specific directory
#
# Output files written:
#   /tmp/${PREFIX}_format_full.txt    — complete dart format output
#   /tmp/${PREFIX}_format_diff.txt    — files that need formatting
#   /tmp/${PREFIX}_format_summary.txt — summary

set -uo pipefail
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

VERBOSE=false
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--verbose" ]; then
    VERBOSE=true
  else
    ARGS+=("$arg")
  fi
done

LOGFILE="/tmp/${PREFIX}_format_full.txt"
DIFFFILE="/tmp/${PREFIX}_format_diff.txt"
SUMMARYFILE="/tmp/${PREFIX}_format_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

MODE="${ARGS[0]:-check}"
TARGET="${ARGS[1]:-.}"

echo "[$TIMESTAMP] dart format mode=$MODE target=$TARGET" >"$LOGFILE"

if [ "$MODE" = "fix" ]; then
  dart format --line-length 100 "$TARGET" >>"$LOGFILE" 2>&1
  FORMAT_EXIT=$?
else
  dart format --line-length 100 --set-exit-if-changed --output=none \
    "$TARGET" >>"$LOGFILE" 2>&1
  FORMAT_EXIT=$?
fi

# Only match lines listing actual changed/would-change files (not the summary line)
grep -E "^(Changed|Would change) " "$LOGFILE" \
  >"$DIFFFILE" 2>/dev/null || true

CHANGED_COUNT=$(wc -l <"$DIFFFILE" | tr -d ' ')

{
  echo "=== dart format summary ==="
  echo "Timestamp : $TIMESTAMP"
  echo "Mode      : $MODE"
  echo "Target    : $TARGET"
  echo "Line len  : 100"
  echo ""
  echo "Changed   : $CHANGED_COUNT file(s)"
  echo "Exit      : $FORMAT_EXIT"
  echo ""
  if [ -s "$DIFFFILE" ]; then
    echo "--- Files needing format ---"
    cat "$DIFFFILE"
  else
    if [ "$MODE" = "check" ]; then
      echo "All files correctly formatted."
    else
      echo "Formatting applied."
    fi
  fi
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "--- Full output ---"
    cat "$LOGFILE"
  fi
} | tee "$SUMMARYFILE"

exit "$FORMAT_EXIT"
