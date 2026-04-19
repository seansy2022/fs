#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
FLUTTER_BIN="${FLUTTER_BIN:-/Users/sean/work/flutter/bin/flutter}"

cd "$ROOT_DIR"

echo "[harness] flutter analyze"
"$FLUTTER_BIN" analyze

echo "[harness] flutter test"
"$FLUTTER_BIN" test

echo "[harness] preflight passed"
