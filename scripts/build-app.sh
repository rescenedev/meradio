#!/bin/bash
# Builds meradio.app — a self-contained macOS menu-bar app bundle (ad-hoc signed).
set -euo pipefail

CONFIG="${1:-release}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/meradio.app"

cd "$ROOT"

echo "==> Building ($CONFIG)…"
swift build -c "$CONFIG"
BIN_PATH="$(swift build -c "$CONFIG" --show-bin-path)"

echo "==> Assembling bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/meradio" "$APP/Contents/MacOS/meradio"
cp "$ROOT/scripts/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Sources/meradio/Resources/stations.json" "$APP/Contents/Resources/stations.json"

echo "==> Ad-hoc code signing…"
codesign --force --deep --sign - "$APP"

echo "==> Done: $APP"
echo "    Launch with: open \"$APP\""
