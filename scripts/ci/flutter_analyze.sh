#!/usr/bin/env bash
# scripts/ci/flutter_analyze.sh
#
# Run flutter analyze, capture verbose output to /tmp, print summary to stdout.
# Usage:
#   ./scripts/ci/flutter_analyze.sh                    # summary with info breakdown
#   ./scripts/ci/flutter_analyze.sh --verbose          # summary + full analyzer output
#   ./scripts/ci/flutter_analyze.sh lib/src/model/     # specific directory
#
# Output files written:
#   /tmp/${PREFIX}_analyze_full.txt    — complete analyzer output
#   /tmp/${PREFIX}_analyze_errors.txt  — errors only
#   /tmp/${PREFIX}_analyze_warnings.txt — warnings only
#   /tmp/${PREFIX}_analyze_summary.txt — counts + exit code

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

LOGFILE="/tmp/${PREFIX}_analyze_full.txt"
ERRORFILE="/tmp/${PREFIX}_analyze_errors.txt"
WARNFILE="/tmp/${PREFIX}_analyze_warnings.txt"
SUMMARYFILE="/tmp/${PREFIX}_analyze_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

TARGET="${ARGS[0]:-}"

echo "[$TIMESTAMP] flutter analyze $TARGET" >"$LOGFILE"
if [ -n "$TARGET" ]; then
  flutter analyze "$TARGET" >>"$LOGFILE" 2>&1
  ANALYZE_EXIT=$?
else
  flutter analyze >>"$LOGFILE" 2>&1
  ANALYZE_EXIT=$?
fi

# Split by severity
grep -E "^\s*error\s*•" "$LOGFILE" >"$ERRORFILE" 2>/dev/null || true
grep -E "^\s*warning\s*•" "$LOGFILE" >"$WARNFILE" 2>/dev/null || true

ERROR_COUNT=$(wc -l <"$ERRORFILE" | tr -d ' ')
WARN_COUNT=$(wc -l <"$WARNFILE" | tr -d ' ')
INFO_COUNT=$(grep -cE "^\s*info\s*•" "$LOGFILE" 2>/dev/null || true)
INFO_COUNT=${INFO_COUNT:-0}

{
  echo "=== flutter analyze summary ==="
  echo "Timestamp : $TIMESTAMP"
  echo "Target    : ${TARGET:-all}"
  echo ""
  echo "Errors    : $ERROR_COUNT"
  echo "Warnings  : $WARN_COUNT"
  echo "Info      : $INFO_COUNT"
  echo "Exit      : $ANALYZE_EXIT"
  echo ""
  if [ "$ERROR_COUNT" -gt 0 ]; then
    echo "--- Errors ---"
    cat "$ERRORFILE"
    echo ""
  fi
  if [ "$WARN_COUNT" -gt 0 ]; then
    echo "--- Warnings ---"
    cat "$WARNFILE"
    echo ""
  fi
  if [ "$INFO_COUNT" -gt 0 ]; then
    echo "--- Info by rule ---"
    grep -E "^\s*info\s*•" "$LOGFILE" | sed 's/.*• //' | sort | uniq -c | sort -rn
    echo ""
  fi
  if [ "$ANALYZE_EXIT" -eq 0 ]; then
    echo "No issues found."
  fi
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "--- Full output ---"
    cat "$LOGFILE"
  fi
} | tee "$SUMMARYFILE"

exit "$ANALYZE_EXIT"
