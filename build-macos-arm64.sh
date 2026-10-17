#!/bin/bash
# Local arm64 macOS build for Macast (Apple Silicon native, no Rosetta).
#
# Why not py2app? setup_py2app.py is the project's historical packager, but
# py2app 0.28.10 breaks on Python 3.11+ at build_app.py:2443:
#
#     import zlib
#     self.copy_file(zlib.__file__, ...)
#
# zlib became a builtin module with no __file__, so this raises AttributeError
# and aborts the bundle. PyInstaller handles the same interpreter fine, so this
# script uses PyInstaller and then fixes up what PyInstaller leaves to the
# caller: Info.plist keys and code signing.
#
# Usage: ./build-macos-arm64.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
BUILD="${BUILD_DIR:-/tmp/macast-build}"
PY="${PYTHON:-python3}"
MPV_VERSION="${MPV_VERSION:-0.41.0}"
PYDIST="$BUILD/dist"
DMG="$BUILD/Macast-MacOS-arm64-v$(cat "$ROOT/macast/.version").dmg"

echo "==> Macast arm64 build"
echo "    root:  $ROOT"
echo "    build: $BUILD"
mkdir -p "$BUILD"

echo "==> [1/7] compiling translations"
"$PY" "$ROOT/build_tools/po2mo.py"

echo "==> [2/7] fetching mpv $MPV_VERSION (arm64)"
if [ ! -x "$BUILD/mpv/MacOS/mpv" ]; then
  cd "$BUILD"
  curl -fsSL -o mpv.zip \
    "https://github.com/mpv-player/mpv/releases/download/v${MPV_VERSION}/mpv-v${MPV_VERSION}-macos-15-arm.zip"
  unzip -q -o mpv.zip            # yields mpv.tar.gz
  tar -xzf mpv.tar.gz           # yields mpv.app/
  # copy the whole MacOS dir: mpv links 97 dylibs via @executable_path/lib
  mkdir -p mpv
  cp -R mpv.app/Contents/MacOS mpv/MacOS
fi
lipo -info "$BUILD/mpv/MacOS/mpv"

echo "==> [3/7] running PyInstaller (onedir)"
"$PY" -m PyInstaller --noconfirm --onedir -w \
  --additional-hooks-dir="$ROOT" \
  --add-data="$ROOT/macast/.version:." \
  --add-data="$ROOT/macast/xml/*:macast/xml" \
  --add-data="$ROOT/i18n/zh_CN/LC_MESSAGES/*.mo:i18n/zh_CN/LC_MESSAGES" \
  --add-data="$ROOT/macast/assets/*:macast/assets" \
  --add-data="$ROOT/macast/assets/fonts/*:macast/assets/fonts" \
  --add-binary="$BUILD/mpv/MacOS/mpv:bin/MacOS" \
  --add-binary="$BUILD/mpv/MacOS/lib/*:bin/MacOS/lib" \
  --exclude-module=tkinter \
  --distpath="$PYDIST" \
  --workpath="$BUILD/work" \
  --specpath="$BUILD/spec" \
  --icon="$ROOT/macast/assets/icon.icns" \
  "$ROOT/Macast.py"

APP="$PYDIST/Macast.app"

echo "==> [4/7] fixing Info.plist"
# PyInstaller does not read setup_py2app.py's plist dict, so set the keys here.
PB=/usr/libexec/PlistBuddy
set_key() { $PB -c "Set :$1 $2" "$APP/Contents/Info.plist" 2>/dev/null \
         || $PB -c "Add :$1 $2" "$APP/Contents/Info.plist" 2>/dev/null || true; }
set_key CFBundleIdentifier "cn.xfangfang.Macast"
set_key LSMinimumSystemVersion "11.0"
set_key LSUIElement "true"
set_key NSHighResolutionCapable "true"
set_key NSLocalNetworkUsageDescription \
  "'Macast needs local network access to be discovered and stream media to DLNA devices.'"

echo "==> [5/7] signing for arm64"
"$ROOT/build_tools/sign-arm64.sh" "$APP"

echo "==> [6/7] verifying"
ARCH=$(lipo -info "$APP/Contents/MacOS/Macast" | sed 's/.*: //')
echo "    architecture: $ARCH"
case "$ARCH" in *arm64*) ;; *) echo "ERROR: expected arm64" >&2; exit 1 ;; esac
codesign --verify --verbose=2 "$APP"
# grep exits 1 when it finds nothing, which under `set -o pipefail` would abort
# the script even though "no non-arm64 .so" is the outcome we want.
BAD=$(find "$APP/Contents" -name "*.so" -exec lipo -info {} \; | grep -v arm64 | wc -l | tr -d ' ' || true)
if [ "${BAD:-0}" != "0" ]; then
  echo "ERROR: $BAD non-arm64 .so found in bundle" >&2
  exit 1
fi
echo "    all .so are arm64"

echo "==> [7/7] building DMG"
STAGE="$BUILD/stage"
rm -rf "$STAGE"
mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "Macast-arm64" -srcfolder "$STAGE" -ov -format UDZO "$DMG" >/dev/null

echo
echo "==> done: $DMG"
ls -lh "$DMG"