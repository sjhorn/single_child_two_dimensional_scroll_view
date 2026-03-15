#!/usr/bin/env bash
# scripts/ci/capture.sh
#
# Run any command with stderr merged into stdout, log to /tmp, print output.
# Use this instead of 2>&1 or > in Bash tool calls.
#
# Usage:
#   ./scripts/ci/capture.sh <label> <command> [args...]
#
# Examples:
#   ./scripts/ci/capture.sh pubget flutter pub get
#   ./scripts/ci/capture.sh dartdoc dart doc --validate-links
#
# Output files written:
#   /tmp/${PREFIX}_capture_<label>.txt — full command output

set -uo pipefail
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

LABEL="${1:?Usage: capture.sh <label> <command> [args...]}"
shift

LOGFILE="/tmp/${PREFIX}_capture_${LABEL}.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

echo "[$TIMESTAMP] $*" >"$LOGFILE"
"$@" >>"$LOGFILE" 2>&1
EXIT=$?

cat "$LOGFILE"
exit "$EXIT"
