#!/usr/bin/env bash
# scripts/ci/dart_fix.sh
#
# Run dart fix to apply automated lint fixes.
# Verbose output captured to /tmp, summary printed to stdout.
# Usage:
#   ./scripts/ci/dart_fix.sh preview            # summary only (default)
#   ./scripts/ci/dart_fix.sh apply              # apply fixes
#   ./scripts/ci/dart_fix.sh preview --verbose  # summary + full output
#   ./scripts/ci/dart_fix.sh preview lib/       # preview specific directory
#
# Output files written:
#   /tmp/${PREFIX}_fix_full.txt    — complete dart fix output
#   /tmp/${PREFIX}_fix_changes.txt — list of proposed/applied changes
#   /tmp/${PREFIX}_fix_summary.txt — summary

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

LOGFILE="/tmp/${PREFIX}_fix_full.txt"
CHANGEFILE="/tmp/${PREFIX}_fix_changes.txt"
SUMMARYFILE="/tmp/${PREFIX}_fix_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

MODE="${ARGS[0]:-preview}"
TARGET="${ARGS[1]:-.}"

echo "[$TIMESTAMP] dart fix mode=$MODE target=$TARGET" >"$LOGFILE"

if [ "$MODE" = "apply" ]; then
  dart fix --apply "$TARGET" >>"$LOGFILE" 2>&1
  FIX_EXIT=$?
else
  dart fix --dry-run "$TARGET" >>"$LOGFILE" 2>&1
  FIX_EXIT=$?
fi

# Extract change lines
grep -E "^(Would fix|Fixed|Applying|\s+lib/|\s+test/)" "$LOGFILE" \
  >"$CHANGEFILE" 2>/dev/null || true

CHANGE_COUNT=$(wc -l <"$CHANGEFILE" | tr -d ' ')

{
  echo "=== dart fix summary ==="
  echo "Timestamp : $TIMESTAMP"
  echo "Mode      : $MODE"
  echo "Target    : $TARGET"
  echo ""
  echo "Changes   : $CHANGE_COUNT"
  echo "Exit      : $FIX_EXIT"
  echo ""
  if [ -s "$CHANGEFILE" ]; then
    echo "--- Proposed/applied changes ---"
    cat "$CHANGEFILE"
  else
    echo "No fixes available."
  fi
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "--- Full output ---"
    cat "$LOGFILE"
  fi
} | tee "$SUMMARYFILE"

exit "$FIX_EXIT"
