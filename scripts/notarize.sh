#!/bin/bash
# Notarizes and staples dist/meradio.dmg.
#
# Uses a stored notarytool keychain profile. Reuses the shared "pomodoro-notary"
# profile by default (notarization credentials are per Apple account, not per app).
# Override with: NOTARY_PROFILE=my-profile scripts/notarize.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DMG="$ROOT/dist/meradio.dmg"
PROFILE="${NOTARY_PROFILE:-pomodoro-notary}"

[ -f "$DMG" ] || { echo "Missing $DMG — run scripts/package-dmg.sh first."; exit 1; }

echo "==> Submitting for notarization (profile: $PROFILE)…"
xcrun notarytool submit "$DMG" --keychain-profile "$PROFILE" --wait

echo "==> Stapling ticket to DMG…"
xcrun stapler staple "$DMG"
xcrun stapler validate "$DMG"

echo "==> Notarized & stapled: $DMG"
