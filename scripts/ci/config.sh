#!/usr/bin/env bash
# scripts/ci/config.sh — Derives settings from pubspec.yaml. No manual editing needed.
_CFG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_CFG_ROOT="$(cd "$_CFG_DIR/../.." && pwd)"
PROJECT_NAME=$(sed -n 's/^name: *//p' "$_CFG_ROOT/pubspec.yaml")
PREFIX="${PROJECT_NAME:0:2}"
