#!/bin/bash
# Builds meradio.app, signs it with Developer ID + hardened runtime, and
# packages a distributable DMG. Run scripts/notarize.sh afterwards to notarize.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
APP="$ROOT/meradio.app"
DIST="$ROOT/dist"
DMG="$DIST/meradio.dmg"
IDENTITY="${SIGN_IDENTITY:-Developer ID Application: Seongil Park (589U6DQJN8)}"
VOLNAME="meradio"

cd "$ROOT"

echo "==> Building release…"
swift build -c release
BIN_PATH="$(swift build -c release --show-bin-path)"

echo "==> Assembling app bundle…"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_PATH/meradio" "$APP/Contents/MacOS/meradio"
cp "$ROOT/scripts/Info.plist" "$APP/Contents/Info.plist"
cp "$ROOT/Sources/meradio/Resources/stations.json" "$APP/Contents/Resources/stations.json"

echo "==> Signing app (Developer ID, hardened runtime, secure timestamp)…"
codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
codesign --verify --strict --verbose=2 "$APP"

echo "==> Building DMG…"
mkdir -p "$DIST"
rm -f "$DMG"
STAGING="$(mktemp -d)"
cp -R "$APP" "$STAGING/"
ln -s /Applications "$STAGING/Applications"
hdiutil create -volname "$VOLNAME" -srcfolder "$STAGING" -ov -format UDZO "$DMG" >/dev/null
rm -rf "$STAGING"

echo "==> Signing DMG…"
codesign --force --sign "$IDENTITY" "$DMG"

echo "==> Done: $DMG"
echo "    Next: scripts/notarize.sh"
