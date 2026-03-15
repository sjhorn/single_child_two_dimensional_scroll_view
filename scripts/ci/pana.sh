#!/usr/bin/env bash
# scripts/ci/pana.sh
#
# Run pana (pub.dev package analysis), capture output, print summary.
# Pana must be listed as a dev_dependency in pubspec.yaml.
#
# Usage:
#   ./scripts/ci/pana.sh              # summary only
#   ./scripts/ci/pana.sh --verbose    # summary + full pana output
#
# Output files written:
#   /tmp/${PREFIX}_pana_full.txt    — complete pana output
#   /tmp/${PREFIX}_pana_summary.txt — score + exit code

set -uo pipefail
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

VERBOSE=false
for arg in "$@"; do
  if [ "$arg" = "--verbose" ]; then
    VERBOSE=true
  fi
done

LOGFILE="/tmp/${PREFIX}_pana_full.txt"
SUMMARYFILE="/tmp/${PREFIX}_pana_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] pana analysis" >"$LOGFILE"
dart run pana --no-warning . >>"$LOGFILE" 2>&1
PANA_EXIT=$?

# Extract the score line (e.g. "Points: 140/160")
SCORE_LINE=$(grep -E "^Points:" "$LOGFILE" 2>/dev/null || echo "Points: unknown")

{
  echo "=== pana summary ==="
  echo "Timestamp : $TIMESTAMP"
  echo ""
  echo "$SCORE_LINE"
  echo "Exit      : $PANA_EXIT"
  echo ""
  if [ "$PANA_EXIT" -ne 0 ]; then
    echo "--- Suggestions ---"
    grep -A1 -E "^\* " "$LOGFILE" 2>/dev/null || echo "(none parsed)"
    echo ""
  fi
  if [ "$VERBOSE" = true ]; then
    echo ""
    echo "--- Full output ---"
    cat "$LOGFILE"
  fi
} | tee "$SUMMARYFILE"

exit "$PANA_EXIT"
