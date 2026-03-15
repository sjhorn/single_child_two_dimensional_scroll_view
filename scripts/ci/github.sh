#!/usr/bin/env bash
# scripts/ci/github.sh
#
# GitHub workflow helper. Wraps common gh CLI operations.
#
# Usage:
#   ./scripts/ci/github.sh status                # check auth
#   ./scripts/ci/github.sh list                  # list ready issues
#   ./scripts/ci/github.sh view <number>         # view issue
#   ./scripts/ci/github.sh start <number>        # claim + branch + label
#   ./scripts/ci/github.sh create "<title>"      # create issue with template body
#   ./scripts/ci/github.sh create --title "<t>" --body-file /tmp/body.md --label "chore" --repo "owner/repo"
#   ./scripts/ci/github.sh pr <number>           # push + create PR (auto title/body)
#   ./scripts/ci/github.sh pr <number> --title "<t>" --body-file /tmp/body.md --repo "owner/repo"
#   ./scripts/ci/github.sh update <number> --body-file /tmp/body.md  # update issue body
#   ./scripts/ci/github.sh finish <number>       # label in-review
#   ./scripts/ci/github.sh done <number>         # label done + close

set -euo pipefail

CMD="${1:-help}"
shift || true

case "$CMD" in
  status)
    gh auth status
    ;;

  list)
    gh issue list --label "ready" --json number,title,labels,assignees
    ;;

  view)
    NUM="$1"
    gh issue view "$NUM" --json title,body,labels,assignees,milestone
    ;;

  start)
    NUM="$1"
    TITLE=$(gh issue view "$NUM" --json title --jq '.title')
    # Slugify: lowercase, replace non-alphanum with hyphens, trim
    SLUG=$(echo "$TITLE" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//' | sed 's/-$//' | head -c 40)
    BRANCH="feat/issue-${NUM}-${SLUG}"
    gh issue edit "$NUM" --add-assignee "@me"
    gh issue edit "$NUM" --add-label "in-progress" --remove-label "ready" 2>/dev/null || \
      gh issue edit "$NUM" --add-label "in-progress"
    git checkout -b "$BRANCH"
    echo "Branch: $BRANCH"
    echo "Issue #$NUM marked in-progress"
    ;;

  create)
    TITLE=""
    BODY_FILE=""
    LABEL="ready"
    REPO=""

    while [ $# -gt 0 ]; do
      case "$1" in
        --title)    TITLE="$2";     shift 2 ;;
        --body-file) BODY_FILE="$2"; shift 2 ;;
        --label)    LABEL="$2";     shift 2 ;;
        --repo)     REPO="$2";      shift 2 ;;
        *)
          if [ -z "$TITLE" ]; then
            TITLE="$1"
          fi
          shift ;;
      esac
    done

    if [ -z "$TITLE" ]; then
      echo "Error: title is required"
      exit 1
    fi

    if [ -n "$BODY_FILE" ]; then
      BODY=$(cat "$BODY_FILE")
    else
      BODY=$(cat <<'TEMPLATE'
## Goal
One sentence describing the outcome.

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

## Out of Scope
What this issue explicitly does NOT cover.
TEMPLATE
)
    fi

    REPO_ARGS=""
    if [ -n "$REPO" ]; then
      REPO_ARGS="--repo $REPO"
    fi

    gh issue create --title "$TITLE" --body "$BODY" --label "$LABEL" $REPO_ARGS
    ;;

  pr)
    NUM=""
    PR_TITLE=""
    BODY_FILE=""
    REPO=""

    while [ $# -gt 0 ]; do
      case "$1" in
        --title)     PR_TITLE="$2"; shift 2 ;;
        --body-file) BODY_FILE="$2"; shift 2 ;;
        --repo)      REPO="$2";     shift 2 ;;
        *)
          if [ -z "$NUM" ]; then
            NUM="$1"
          fi
          shift ;;
      esac
    done

    if [ -z "$NUM" ]; then
      echo "Error: issue number is required"
      exit 1
    fi

    REPO_ARGS=""
    if [ -n "$REPO" ]; then
      REPO_ARGS="--repo $REPO"
    fi

    if [ -z "$PR_TITLE" ]; then
      PR_TITLE="$(gh issue view "$NUM" --json title --jq '.title' $REPO_ARGS) (#$NUM)"
    fi

    if [ -n "$BODY_FILE" ]; then
      PR_BODY=$(cat "$BODY_FILE")
    else
      PR_BODY="Closes #$NUM"
    fi

    BRANCH=$(git branch --show-current)
    git push -u origin "$BRANCH"
    gh pr create --title "$PR_TITLE" --body "$PR_BODY" $REPO_ARGS
    gh issue edit "$NUM" --add-label "in-review" --remove-label "in-progress" $REPO_ARGS 2>/dev/null || \
      gh issue edit "$NUM" --add-label "in-review" $REPO_ARGS
    echo "PR created from $BRANCH, issue #$NUM marked in-review"
    ;;

  update)
    NUM=""
    BODY_FILE=""
    REPO=""

    while [ $# -gt 0 ]; do
      case "$1" in
        --body-file) BODY_FILE="$2"; shift 2 ;;
        --repo)      REPO="$2";     shift 2 ;;
        *)
          if [ -z "$NUM" ]; then
            NUM="$1"
          fi
          shift ;;
      esac
    done

    if [ -z "$NUM" ] || [ -z "$BODY_FILE" ]; then
      echo "Error: usage: github.sh update <number> --body-file <path>"
      exit 1
    fi

    REPO_ARGS=""
    if [ -n "$REPO" ]; then
      REPO_ARGS="--repo $REPO"
    fi

    BODY=$(cat "$BODY_FILE")
    gh issue edit "$NUM" --body "$BODY" $REPO_ARGS
    echo "Issue #$NUM body updated"
    ;;

  finish)
    NUM="$1"
    gh issue edit "$NUM" --add-label "in-review" --remove-label "in-progress" 2>/dev/null || \
      gh issue edit "$NUM" --add-label "in-review"
    echo "Issue #$NUM marked in-review"
    ;;

  done)
    NUM="$1"
    gh issue edit "$NUM" --add-label "done" --remove-label "in-review" 2>/dev/null || \
      gh issue edit "$NUM" --add-label "done"
    gh issue close "$NUM"
    echo "Issue #$NUM closed and marked done"
    ;;

  help|*)
    echo "Usage: github.sh {status|list|view|start|create|pr|update|finish|done} [args]"
    echo ""
    echo "Commands:"
    echo "  status              Check gh auth"
    echo "  list                List ready issues"
    echo "  view <number>       View issue details"
    echo "  start <number>      Claim + label in-progress + create branch"
    echo "  create \"<title>\"    Create new issue with template body"
    echo "    --title <t>       Issue title (or use positional arg)"
    echo "    --body-file <f>   Read body from file instead of template"
    echo "    --label <l>       Label (default: ready)"
    echo "    --repo <r>        Target repo (default: current)"
    echo "  pr <number>         Push branch + create PR closing issue"
    echo "    --title <t>       PR title (default: issue title)"
    echo "    --body-file <f>   PR body from file (default: 'Closes #N')"
    echo "    --repo <r>        Target repo (default: current)"
    echo "  update <number>     Update issue body"
    echo "    --body-file <f>   New body content from file"
    echo "    --repo <r>        Target repo (default: current)"
    echo "  finish <number>     Label in-review"
    echo "  done <number>       Label done + close"
    exit 1
    ;;
esac
