#!/bin/bash
# Builds "Snoopy & Bambi" and installs it as ~/Applications/SnoopyAndBambi.app,
# using only the Swift command line tools (no Xcode needed).
#
# It's built and signed in a temporary folder first: this project lives in
# Documents, which iCloud Drive tags with file attributes that code signing
# refuses. ~/Applications is also where Spotlight looks first for apps.
set -euo pipefail
cd "$(dirname "$0")"

NAME="SnoopyAndBambi.app"
STAGE="${TMPDIR:-/tmp}/SnoopyAndBambi-build"
DEST="$HOME/Applications"

rm -rf "$STAGE"
mkdir -p "$STAGE/$NAME/Contents/MacOS" "$STAGE/$NAME/Contents/Resources"

swiftc -O -swift-version 5 \
  Sources/*.swift \
  -o "$STAGE/$NAME/Contents/MacOS/SnoopyAndBambi" \
  -framework AppKit -framework SpriteKit -framework UserNotifications

# Copy painted bunny sprite sheets into Contents/Resources/Sprites (if present).
if [ -d "Resources/Sprites" ]; then
  mkdir -p "$STAGE/$NAME/Contents/Resources/Sprites"
  for f in Resources/Sprites/*.png; do
    [ -f "$f" ] && cat "$f" > "$STAGE/$NAME/Contents/Resources/Sprites/$(basename "$f")"
  done
fi

# Write (not copy) the plist so no extended attributes come along.
cat Info.plist > "$STAGE/$NAME/Contents/Info.plist"
xattr -cr "$STAGE/$NAME" 2>/dev/null || true
# Ad-hoc signature so macOS treats it as a proper local app.
codesign --force --sign - "$STAGE/$NAME" >/dev/null

mkdir -p "$DEST"
rm -rf "$DEST/$NAME"
ditto "$STAGE/$NAME" "$DEST/$NAME"
rm -rf "$STAGE"
echo "Installed $DEST/$NAME"
