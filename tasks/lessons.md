# Lessons Learned

Record corrections and discoveries here so they are not repeated.

## 2026-03-15: Never run flutter/dart commands directly
Always use `scripts/ci/` wrappers. Do not run `flutter pub get`, `flutter test`, `flutter analyze`, `dart format` etc. directly in Bash tool calls. Also avoid raw shell constructs like `$()`, `|`, `>`, `&&`, `||`, `2>&1` in Bash tool calls — the CI wrappers handle piping internally. Never prefix commands with `bash` — run scripts directly (e.g. `scripts/ci/ci_gate.sh`, not `bash scripts/ci/ci_gate.sh`). For ad-hoc commands, use `scripts/ci/capture.sh <label> <command> [args...]`.
