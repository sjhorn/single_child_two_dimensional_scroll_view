# CLAUDE.md

## Rules

- **All work starts from a GitHub issue.** No issue → create one before writing code.
- **TDD is mandatory.** Failing test → implement → refactor → commit.
- **`qa` agent gates every commit.** Never run `flutter test`, `flutter analyze`, `dart format` directly — always `scripts/ci/` wrappers.
- **Every public symbol has `///` dartdoc.** Zero `dart doc` warnings.
- **90% test coverage for all code**
- **Commit format:** `type(scope): description` — one ROADMAP checkbox per commit max.
- **No raw shell in Bash tool calls.** In Bash tool calls, never use `$()`, `sed`, `|`, `>`, `&&`, `||`, `tr`, `2>&1`. Never prefix commands with `bash` — run scripts directly (e.g. `scripts/ci/ci_gate.sh`, not `bash scripts/ci/ci_gate.sh`). The `scripts/ci/` wrappers handle shell complexity internally. For ad-hoc commands, use `scripts/ci/capture.sh <label> <command> [args...]`.
- **After any user correction** → update `tasks/lessons.md`.
- **Domain layer (`lib/src/domain/`) is pure Dart** — no Flutter imports.
- **No `dynamic` types.**
- **No business logic in widgets.**

---

Reference ROADMAP.md and tasks/lessons.md for memory

---
## Agents

Delegate: **"use the `<name>` agent to `<task>`"**

| Task | Agent |
|------|-------|
| Entities, value objects, business logic | `domain` |
| Platform services, data sources, integrations | `infrastructure` |
| Widgets, render objects, UI components | `presentation` |
| End-to-end / integration tests | `integration` |
| Performance benchmarks | `benchmark` |
| Docs, examples, README, CHANGELOG | `docs` |
| Run tests, analyze, format, coverage | `qa` |
| GitHub issues, PRs, labels, branches | `github` |

**Before every commit** → `qa`. **After public API changes** → `docs`.

Cross-layer order: `domain → infrastructure → presentation → qa → docs → commit`

---

## Workflow

1. **Issue** — `use the github agent to start <number>` (or `create` if none exists)
2. **Red** — `use the <owning> agent to write a failing test for <task>` → `use the qa agent to confirm it fails`
3. **Green** — `use the <owning> agent to implement minimum to pass` → `use the qa agent to confirm it passes`
4. **Refactor** — `use the <owning> agent to refactor` → `use the qa agent to confirm still green`
5. **Gate** — `use the qa agent to run the full gate`
6. **Commit** — `type(scope): description`
7. **Repeat** steps 2–6 for each behaviour in the issue
8. **PR** — `use the github agent to pr <number>` → tick ROADMAP checkbox
9. **Stop** — Do not start the next issue until the PR is submitted

> Example: user says "add a bold toggle to the toolbar"
> → `use the github agent to create "Add bold toggle to toolbar"` → gets issue #12
> → `use the github agent to start 12` → creates branch, labels in-progress
> → continue to step 2 with the owning agent

> Example: all behaviours for #12 are committed
> → `use the github agent to pr 12` → creates PR "Add bold toggle to toolbar (#12)", labels in-review
> → update ROADMAP.md: `- [ ]` → `- [x]`
