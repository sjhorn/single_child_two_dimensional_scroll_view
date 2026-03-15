#!/usr/bin/env bash
# scripts/ci/log_tail.sh
#
# Read, tail, or grep the captured /tmp log files.
# Usage:
#   ./scripts/ci/log_tail.sh summary          # print all summaries
#   ./scripts/ci/log_tail.sh tail test        # tail last 40 lines of test log
#   ./scripts/ci/log_tail.sh tail analyze     # tail last 40 lines of analyze log
#   ./scripts/ci/log_tail.sh grep "FAILED"    # grep pattern across all logs
#   ./scripts/ci/log_tail.sh grep "error" analyze  # grep specific log
#   ./scripts/ci/log_tail.sh failures         # show only failing tests

set -euo pipefail

# Send all output (including errors) to stdout so callers never need 2>&1.
exec 2>&1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Map log name to file path (bash 3 compatible — no associative arrays).
log_file() {
  case "$1" in
    test)             echo "/tmp/${PREFIX}_test_full.txt" ;;
    test_fail)        echo "/tmp/${PREFIX}_test_fail.txt" ;;
    test_summary)     echo "/tmp/${PREFIX}_test_summary.txt" ;;
    analyze)          echo "/tmp/${PREFIX}_analyze_full.txt" ;;
    analyze_errors)   echo "/tmp/${PREFIX}_analyze_errors.txt" ;;
    analyze_summary)  echo "/tmp/${PREFIX}_analyze_summary.txt" ;;
    format)           echo "/tmp/${PREFIX}_format_full.txt" ;;
    format_summary)   echo "/tmp/${PREFIX}_format_summary.txt" ;;
    fix)              echo "/tmp/${PREFIX}_fix_full.txt" ;;
    fix_summary)      echo "/tmp/${PREFIX}_fix_summary.txt" ;;
    coverage)         echo "/tmp/${PREFIX}_coverage_summary.txt" ;;
    gate)             echo "/tmp/${PREFIX}_gate_summary.txt" ;;
    *)                echo "/tmp/${PREFIX}_${1}_full.txt" ;;
  esac
}

ALL_NAMES="test test_fail test_summary analyze analyze_errors analyze_summary format format_summary fix fix_summary coverage gate"

CMD="${1:-summary}"

case "$CMD" in
  summary)
    echo "=== ${PROJECT_NAME} CI log summaries ==="
    echo ""
    for name in gate test_summary analyze_summary format_summary coverage; do
      file=$(log_file "$name")
      if [ -f "$file" ]; then
        echo "--- $name ---"
        cat "$file"
        echo ""
      fi
    done
    ;;

  tail)
    TARGET="${2:-test}"
    LINES="${3:-40}"
    file=$(log_file "$TARGET")
    if [ -f "$file" ]; then
      echo "=== tail -n $LINES $file ==="
      tail -n "$LINES" "$file"
    else
      echo "Log not found: $file" >&2
      exit 1
    fi
    ;;

  grep)
    PATTERN="${2:?Usage: log_tail.sh grep PATTERN [logname]}"
    TARGET="${3:-all}"
    if [ "$TARGET" = "all" ]; then
      for name in $ALL_NAMES; do
        file=$(log_file "$name")
        [ -f "$file" ] || continue
        matches=$(grep -nE "$PATTERN" "$file" 2>/dev/null || true)
        if [ -n "$matches" ]; then
          echo "=== $name ($file) ==="
          echo "$matches"
          echo ""
        fi
      done
    else
      file=$(log_file "$TARGET")
      [ -f "$file" ] || { echo "Log not found: $file" >&2; exit 1; }
      grep -nE "$PATTERN" "$file" || echo "(no matches)"
    fi
    ;;

  failures)
    echo "=== Test failures ==="
    fail_file=$(log_file "test_fail")
    if [ -f "$fail_file" ] && [ -s "$fail_file" ]; then
      cat "$fail_file"
    else
      echo "No failures found (or test log missing)."
    fi
    echo ""
    echo "=== Analyze errors ==="
    err_file=$(log_file "analyze_errors")
    if [ -f "$err_file" ] && [ -s "$err_file" ]; then
      cat "$err_file"
    else
      echo "No analyzer errors found."
    fi
    ;;

  list)
    echo "Available logs:"
    for name in $ALL_NAMES; do
      file=$(log_file "$name")
      if [ -f "$file" ]; then
        size=$(wc -l <"$file" | tr -d ' ')
        echo "  $name : $file ($size lines)"
      else
        echo "  $name : (not yet generated)"
      fi
    done
    ;;

  *)
    echo "Usage: log_tail.sh <summary|tail|grep|failures|list> [args]" >&2
    exit 1
    ;;
esac
