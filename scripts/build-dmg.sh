#!/bin/bash
#
# Builds Squish.app (Release, ad-hoc signed) and packages it into a .dmg.
# Usage: ./scripts/build-dmg.sh
#
set -euo pipefail

APP_NAME="Squish"
SCHEME="Squish"
PROJECT="Squish.xcodeproj"
BUILD_DIR="build"
DIST_DIR="dist"

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
ln -s /Applications "$DIST_DIR/staging/Applications"

DMG_PATH="$DIST_DIR/$APP_NAME.dmg"

if command -v create-dmg >/dev/null 2>&1; then
  create-dmg \
    --volname "$APP_NAME" \
    --window-size 540 360 \
    --icon-size 110 \
    --icon "$APP_NAME.app" 140 170 \
    --app-drop-link 400 170 \
    --no-internet-enable \
    "$DMG_PATH" "$DIST_DIR/staging" || true
else
  echo "   (create-dmg not installed — using hdiutil; \`brew install create-dmg\` for a nicer layout)"
  hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$DIST_DIR/staging" \
    -ov -format UDZO \
    "$DMG_PATH"
fi

rm -rf "$DIST_DIR/staging"

echo "==> Done: $DMG_PATH"
shasum -a 256 "$DMG_PATH"
