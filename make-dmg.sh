#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
PRODUCT="PasteShot"
cd "$ROOT"
APP="$ROOT/dist/$PRODUCT.app"
if [ ! -d "$APP" ]; then
  bash "$ROOT/package-app.sh"
fi
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$ROOT/Info.plist")"
STAGING="$ROOT/dist/dmg-staging"
DMG="$ROOT/dist/${PRODUCT}-${VERSION}.dmg"
rm -rf "$STAGING"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/$PRODUCT.app"
ln -s /Applications "$STAGING/Applications"
rm -f "$DMG"
hdiutil create \
  -volname "Paste Shot" \
  -srcfolder "$STAGING" \
  -ov \
  -format UDZO \
  "$DMG"
rm -rf "$STAGING"
echo "$DMG"
