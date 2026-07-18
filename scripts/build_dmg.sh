#!/usr/bin/env bash
# Packages iTake.app as a drag-to-Applications .dmg using create-dmg
# (https://github.com/create-dmg/create-dmg), installing it via Homebrew if it's missing.

set -euo pipefail

CONFIG="${1:-release}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="iTake"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"
VERSION="$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$ROOT_DIR/packaging/Info.plist")"
DMG_PATH="$ROOT_DIR/.build/$APP_NAME-$VERSION.dmg"

"$ROOT_DIR/scripts/build_app.sh" "$CONFIG"

if ! command -v create-dmg >/dev/null 2>&1; then
    echo "==> create-dmg not found, installing via Homebrew"
    brew install create-dmg
fi

rm -f "$DMG_PATH"

echo "==> Building $DMG_PATH"
create-dmg \
    --volname "$APP_NAME" \
    --window-size 540 380 \
    --icon-size 128 \
    --icon "$APP_NAME.app" 140 170 \
    --app-drop-link 400 170 \
    --hide-extension "$APP_NAME.app" \
    "$DMG_PATH" \
    "$APP_BUNDLE"

echo "==> Built: $DMG_PATH"
