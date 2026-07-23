#!/bin/bash
#
# Builds Squish.app (Release, ad-hoc signed) and packages it into a styled .dmg.
# Usage: ./scripts/build-dmg.sh
#
set -euo pipefail

APP_NAME="Squish"
SCHEME="Squish"
PROJECT="Squish.xcodeproj"
BUILD_DIR="build"
DIST_DIR="dist"
BACKGROUND="packaging/dmg-background.png"

cd "$(dirname "$0")/.."

echo "==> Resolving Swift Package dependencies"
xcodebuild -project "$PROJECT" -resolvePackageDependencies >/dev/null

echo "==> Building $APP_NAME (Release)"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR" \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=YES \
  clean build

APP_PATH="$BUILD_DIR/Build/Products/Release/$APP_NAME.app"
if [ ! -d "$APP_PATH" ]; then
  echo "!! Build product not found at $APP_PATH" >&2
  exit 1
fi

echo "==> Packaging DMG"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR/staging"
cp -R "$APP_PATH" "$DIST_DIR/staging/"

DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

# Build a HiDPI (@2x) TIFF background so a 500x300 pt window shows the
# 1000x600 source crisp on Retina. Without this, create-dmg treats the PNG
# as 1x (1px = 1pt) and Finder shows only the top-left quarter, zoomed.
BACKGROUND_HIDPI="$DIST_DIR/dmg-background.tiff"
BACKGROUND_1X="$DIST_DIR/dmg-background-1x.png"
SRC_W=$(sips -g pixelWidth "$BACKGROUND" | awk '/pixelWidth:/{print $2}')
SRC_H=$(sips -g pixelHeight "$BACKGROUND" | awk '/pixelHeight:/{print $2}')
sips -z $((SRC_H / 2)) $((SRC_W / 2)) "$BACKGROUND" --out "$BACKGROUND_1X" >/dev/null
tiffutil -cathidpicheck "$BACKGROUND_1X" "$BACKGROUND" -out "$BACKGROUND_HIDPI" >/dev/null
rm -f "$BACKGROUND_1X"
BACKGROUND="$BACKGROUND_HIDPI"

if command -v create-dmg >/dev/null 2>&1; then
  # Styled DMG with background image. The 1000x700 background is used as @2x,
  # so the window is 500x350 pt (window sized 500x370 to leave room below the
  # icon row for Finder's toolbar/status bar). Icon coords are in points.
  create-dmg \
    --volname "$APP_NAME" \
    --background "$BACKGROUND" \
    --window-pos 200 120 \
    --window-size 500 370 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 106 170 \
    --app-drop-link 391 170 \
    --no-internet-enable \
    "$DMG_PATH" "$DIST_DIR/staging"
else
  echo "   create-dmg not found — falling back to a plain DMG."
  echo "   Install it for the styled window: brew install create-dmg"
  ln -s /Applications "$DIST_DIR/staging/Applications"
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DIST_DIR/staging" \
    -ov -format UDZO \
    "$DMG_PATH"
fi

rm -rf "$DIST_DIR/staging"

echo "==> Done: $DMG_PATH"
shasum -a 256 "$DMG_PATH"
