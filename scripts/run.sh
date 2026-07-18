#!/usr/bin/env bash
# Builds (via build_app.sh) and launches iTake.app.

set -euo pipefail

CONFIG="${1:-debug}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

"$ROOT_DIR/scripts/build_app.sh" "$CONFIG"

echo "==> Launching iTake.app"
open "$ROOT_DIR/.build/iTake.app"
