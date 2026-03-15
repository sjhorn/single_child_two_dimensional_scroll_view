#!/usr/bin/env bash
# scripts/ci/publish.sh
#
# Publish package to pub.dev. Runs validation before publishing.
#
# Usage:
#   ./scripts/ci/publish.sh check              # dry-run: validate without publishing
#   ./scripts/ci/publish.sh release            # validate + publish to pub.dev
#
# Output files written:
#   /tmp/${PREFIX}_publish_full.txt    — complete output
#   /tmp/${PREFIX}_publish_summary.txt — summary + exit code

set -uo pipefail
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

CMD="${1:-help}"

LOGFILE="/tmp/${PREFIX}_publish_full.txt"
SUMMARYFILE="/tmp/${PREFIX}_publish_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Extract version from pubspec.yaml
VERSION=$(sed -n 's/^version: *//p' "$SCRIPT_DIR/../../pubspec.yaml")

case "$CMD" in
  check)
    echo "[$TIMESTAMP] publish dry-run v$VERSION" >"$LOGFILE"

    echo "--- Running ci_gate ---" >>"$LOGFILE"
    "$SCRIPT_DIR/ci_gate.sh" >>"$LOGFILE" 2>&1
    GATE_EXIT=$?
    if [ "$GATE_EXIT" -ne 0 ]; then
      {
        echo "=== publish check FAILED ==="
        echo "ci_gate.sh failed (exit $GATE_EXIT) — fix before publishing"
      } | tee "$SUMMARYFILE"
      exit 1
    fi

    echo "" >>"$LOGFILE"
    echo "--- Running pana ---" >>"$LOGFILE"
    "$SCRIPT_DIR/pana.sh" >>"$LOGFILE" 2>&1 || true

    echo "" >>"$LOGFILE"
    echo "--- Dry run ---" >>"$LOGFILE"
    dart pub publish --dry-run >>"$LOGFILE" 2>&1
    DRY_EXIT=$?

    {
      echo "=== publish check ==="
      echo "Timestamp : $TIMESTAMP"
      echo "Version   : $VERSION"
      echo "CI gate   : PASS"
      echo "Dry run   : $([ "$DRY_EXIT" -eq 0 ] && echo "PASS" || echo "FAIL")"
      echo ""
      if [ "$DRY_EXIT" -ne 0 ]; then
        echo "--- Issues ---"
        grep -E "^(\*|Package|Sorry)" "$LOGFILE" 2>/dev/null || echo "(see full log)"
      else
        echo "Ready to publish. Run: scripts/ci/publish.sh release"
      fi
    } | tee "$SUMMARYFILE"

    exit "$DRY_EXIT"
    ;;

  release)
    echo "[$TIMESTAMP] publish release v$VERSION" >"$LOGFILE"

    # Run dry-run first
    echo "--- Dry run ---" >>"$LOGFILE"
    dart pub publish --dry-run >>"$LOGFILE" 2>&1
    DRY_EXIT=$?

    if [ "$DRY_EXIT" -ne 0 ]; then
      {
        echo "=== publish ABORTED ==="
        echo "Dry run failed — not safe to publish"
        echo ""
        grep -E "^(\*|Package|Sorry)" "$LOGFILE" 2>/dev/null || echo "(see full log)"
      } | tee "$SUMMARYFILE"
      exit 1
    fi

    echo "" >>"$LOGFILE"
    echo "--- Publishing ---" >>"$LOGFILE"
    dart pub publish --force >>"$LOGFILE" 2>&1
    PUB_EXIT=$?

    {
      echo "=== publish release ==="
      echo "Timestamp : $TIMESTAMP"
      echo "Version   : $VERSION"
      echo "Result    : $([ "$PUB_EXIT" -eq 0 ] && echo "PUBLISHED" || echo "FAILED")"
      echo ""
      if [ "$PUB_EXIT" -ne 0 ]; then
        echo "--- Errors ---"
        tail -20 "$LOGFILE"
      else
        echo "Published $PROJECT_NAME v$VERSION to pub.dev"
      fi
    } | tee "$SUMMARYFILE"

    exit "$PUB_EXIT"
    ;;

  help|*)
    echo "Usage: publish.sh {check|release}"
    echo ""
    echo "Commands:"
    echo "  check     Dry-run: ci_gate + pana + dart pub publish --dry-run"
    echo "  release   Validate + publish to pub.dev (--force, no prompt)"
    exit 1
    ;;
esac
