#!/usr/bin/env bash
# scripts/ci/ci_gate.sh
#
# Run the full commit gate: analyze -> format check -> test.
# Each sub-script captures its own verbose output to /tmp log files
# and prints only a summary to stdout.
#
# Usage:
#   ./scripts/ci/ci_gate.sh                  # full gate, summary only
#   ./scripts/ci/ci_gate.sh --fix            # auto-fix format + lint before checking
#   ./scripts/ci/ci_gate.sh --verbose        # full gate, verbose output
#   ./scripts/ci/ci_gate.sh test/src/model/  # gate scoped to one layer
#
# Output files written:
#   /tmp/${PREFIX}_gate_summary.txt — pass/fail per step + overall result
#   (plus each sub-script's own /tmp/${PREFIX}_*.txt files)

set -uo pipefail
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

VERBOSE=false
FIX=false
ARGS=()
for arg in "$@"; do
  if [ "$arg" = "--verbose" ]; then
    VERBOSE=true
  elif [ "$arg" = "--fix" ]; then
    FIX=true
  else
    ARGS+=("$arg")
  fi
done

SUMMARYFILE="/tmp/${PREFIX}_gate_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
SCOPE="${ARGS[0]:-}"

VERBOSE_FLAG=""
if [ "$VERBOSE" = true ]; then
  VERBOSE_FLAG="--verbose"
fi

# Step 0 (optional): auto-fix format + lint
if [ "$FIX" = true ]; then
  echo ">>> dart fix apply"
  "$SCRIPT_DIR/dart_fix.sh" apply $VERBOSE_FLAG ${SCOPE:+"$SCOPE"} || true
  echo ""
  echo ">>> dart format fix"
  "$SCRIPT_DIR/dart_format.sh" fix $VERBOSE_FLAG ${SCOPE:+"$SCOPE"} || true
  echo ""
fi

RESULT_ANALYZE="SKIP"
RESULT_FORMAT="SKIP"
RESULT_TEST="SKIP"
RESULT_COVERAGE="SKIP"
RESULT_DARTDOC="SKIP"
RESULT_EXAMPLE="SKIP"

# Resolve project root (two levels above scripts/ci/).
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Step 1: analyze
echo ">>> flutter analyze"
if "$SCRIPT_DIR/flutter_analyze.sh" $VERBOSE_FLAG ${SCOPE:+"$SCOPE"}; then
  RESULT_ANALYZE="PASS"
else
  RESULT_ANALYZE="FAIL"
fi
echo ""

# Step 2: format check
echo ">>> dart format check"
if "$SCRIPT_DIR/dart_format.sh" check $VERBOSE_FLAG ${SCOPE:+"$SCOPE"}; then
  RESULT_FORMAT="PASS"
else
  RESULT_FORMAT="FAIL"
fi
echo ""

# Step 3: tests
echo ">>> flutter test"
if "$SCRIPT_DIR/flutter_test.sh" $VERBOSE_FLAG ${SCOPE:+"$SCOPE"}; then
  RESULT_TEST="PASS"
else
  RESULT_TEST="FAIL"
fi
echo ""

# Step 4: coverage (90% threshold, skip for scoped runs)
if [ -z "$SCOPE" ]; then
  echo ">>> coverage"
  if "$SCRIPT_DIR/coverage.sh" $VERBOSE_FLAG; then
    RESULT_COVERAGE="PASS"
  else
    RESULT_COVERAGE="FAIL"
  fi
  echo ""
fi

# Step 5: dartdoc validation (skip for scoped runs)
if [ -z "$SCOPE" ]; then
  echo ">>> dart doc"
  DARTDOC_LOG="/tmp/${PREFIX}_dartdoc_full.txt"
  if dart doc --validate-links >"$DARTDOC_LOG" 2>&1; then
    RESULT_DARTDOC="PASS"
  else
    RESULT_DARTDOC="FAIL"
  fi
  DARTDOC_WARNINGS=$(grep -c "warning" "$DARTDOC_LOG" 2>/dev/null || echo "0")
  echo "  Warnings: $DARTDOC_WARNINGS"
  echo ""
fi

# Step 6: example app gate
EXAMPLE_DIR="$PROJECT_ROOT/example"
if [ -z "$SCOPE" ] && [ -f "$EXAMPLE_DIR/pubspec.yaml" ]; then
  echo ">>> example: flutter pub get + analyze + format"
  if (cd "$EXAMPLE_DIR" && flutter pub get --no-example && flutter analyze lib/ && dart format --line-length 100 --set-exit-if-changed lib/); then
    RESULT_EXAMPLE="PASS"
  else
    RESULT_EXAMPLE="FAIL"
  fi
  echo ""
fi

# Determine overall result
OVERALL="PASS"
if [ "$RESULT_ANALYZE" = "FAIL" ] || [ "$RESULT_FORMAT" = "FAIL" ] || [ "$RESULT_TEST" = "FAIL" ] || [ "$RESULT_COVERAGE" = "FAIL" ] || [ "$RESULT_DARTDOC" = "FAIL" ] || [ "$RESULT_EXAMPLE" = "FAIL" ]; then
  OVERALL="FAIL"
fi

{
  echo "=== CI gate summary ==="
  echo "Timestamp : $TIMESTAMP"
  echo "Scope     : ${SCOPE:-all}"
  echo "Fix       : $FIX"
  echo ""
  echo "  flutter analyze   : $RESULT_ANALYZE"
  echo "  dart format check : $RESULT_FORMAT"
  echo "  flutter test      : $RESULT_TEST"
  echo "  coverage (≥90%)   : $RESULT_COVERAGE"
  echo "  dart doc          : $RESULT_DARTDOC"
  echo "  example gate      : $RESULT_EXAMPLE"
  echo ""
  echo "Overall   : $OVERALL"
} | tee "$SUMMARYFILE"

[ "$OVERALL" = "PASS" ] && exit 0 || exit 1
