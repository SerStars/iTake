#!/usr/bin/env bash

set -euo pipefail

CONFIG="${1:-debug}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="iTake"
BUNDLE_ID="com.SerStars.iTake"
BUILD_DIR="$ROOT_DIR/.build/$CONFIG"
APP_BUNDLE="$ROOT_DIR/.build/$APP_NAME.app"

echo "==> Building ($CONFIG)"
swift build --package-path "$ROOT_DIR" -c "$CONFIG"

echo "==> Packaging $APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$ROOT_DIR/packaging/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

if [ -f "$ROOT_DIR/packaging/AppIcon.icns" ]; then
    cp "$ROOT_DIR/packaging/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/AppIcon.icns"
else
    echo "==> No packaging/AppIcon.icns yet -- app will use the default generic icon"
fi

echo "==> Code signing (ad-hoc, stable identifier so TCC grants persist across rebuilds)"
codesign --force --deep --sign - --identifier "$BUNDLE_ID" "$APP_BUNDLE"

echo "==> Built: $APP_BUNDLE"
