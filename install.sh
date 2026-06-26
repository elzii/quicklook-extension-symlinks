#!/bin/bash
# install.sh — installs the QL Symlink Viewer extension from a signed .app bundle.
#
# Usage:
#   ./install.sh "/absolute/path/to/QLSymlinkViewerApp.app"
#   ./install.sh "/absolute/path/to/SomeArchive.xcarchive"
#
# If no path is provided, this script tries:
#   1) newest Xcode Archive product
#   2) DerivedData Debug build
set -euo pipefail

APP_NAME="QLSymlinkViewerApp"
INSTALL_DIR="/Applications"
APP_SOURCE="${1:-}"

# Allow passing an .xcarchive path directly.
if [ -n "$APP_SOURCE" ] && [ -d "$APP_SOURCE" ] && [[ "$APP_SOURCE" == *.xcarchive ]]; then
  APP_SOURCE="$APP_SOURCE/Products/Applications/$APP_NAME.app"
fi

if [ -z "$APP_SOURCE" ]; then
  APP_SOURCE=$(find ~/Library/Developer/Xcode/Archives -name "$APP_NAME.app" -type d 2>/dev/null | tail -1 || true)
fi

if [ -z "$APP_SOURCE" ]; then
  APP_SOURCE=$(find ~/Library/Developer/Xcode/DerivedData/QLSymlinkViewer-*/Build/Products/Debug/"$APP_NAME".app \
    -maxdepth 0 2>/dev/null | head -1 || true)
fi

if [ -z "$APP_SOURCE" ] || [ ! -d "$APP_SOURCE" ]; then
  echo "✗ No app bundle found."
  echo "  Pass an explicit app path, e.g.:"
  echo "  ./install.sh \"/Users/.../QLSymlinkViewerApp.app\""
  exit 1
fi

echo "▶ Source app: $APP_SOURCE"

APPEX="$APP_SOURCE/Contents/PlugIns/QLSymlinkPreview.appex"
if [ ! -d "$APPEX" ]; then
  echo "✗ Missing extension: $APPEX"
  exit 1
fi

TEAM=$(codesign -dv "$APPEX" 2>&1 | awk -F= '/TeamIdentifier=/{print $2}' | tr -d '[:space:]')
if [ -z "$TEAM" ] || [ "$TEAM" = "notset" ] || [ "$TEAM" = "not" ]; then
  echo "✗ Extension is ad-hoc signed — pluginkit won't load it."
  echo "  Sign the app/extension in Xcode (Team + Apple Development), then rerun install.sh."
  exit 1
fi

echo "▶ Signed TeamIdentifier: $TEAM"
echo "▶ Purging old registration..."
if [ -d "$INSTALL_DIR/$APP_NAME.app/Contents/PlugIns/QLSymlinkPreview.appex" ]; then
  pluginkit -r "$INSTALL_DIR/$APP_NAME.app/Contents/PlugIns/QLSymlinkPreview.appex" 2>/dev/null || true
fi

echo "▶ Installing to $INSTALL_DIR/$APP_NAME.app ..."
rm -rf "$INSTALL_DIR/$APP_NAME.app"
cp -R "$APP_SOURCE" "$INSTALL_DIR/"

echo "▶ Registering with Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$INSTALL_DIR/$APP_NAME.app"

echo "▶ Registering extension with pluginkit..."
pluginkit -a "$INSTALL_DIR/$APP_NAME.app/Contents/PlugIns/QLSymlinkPreview.appex" 2>/dev/null || true

echo "▶ Resetting QuickLook daemon..."
qlmanage -r
qlmanage -r cache

echo "▶ Relaunching Finder..."
killall Finder 2>/dev/null || true

echo "✅ Installed. Test with:"
echo "   qlmanage -p /path/to/symlink-or-alias"
