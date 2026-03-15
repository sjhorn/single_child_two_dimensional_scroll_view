#!/usr/bin/env bash
# scripts/ci/sed.sh
#
# Thin wrapper around sed so that agents can call it without interactive
# permission prompts (the script path is in the settings allowlist).
#
# Usage:
#   ./scripts/ci/sed.sh <sed-args...>
#
# Examples:
#   ./scripts/ci/sed.sh -i '' 's/old/new/' file.txt
#   ./scripts/ci/sed.sh -n '/pattern/p' file.txt

set -euo pipefail
exec 2>&1

if [ $# -eq 0 ]; then
  echo "Usage: scripts/ci/sed.sh <sed-args...>"
  exit 1
fi

sed "$@"
