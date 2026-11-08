#!/usr/bin/env bash
# Build Macast for Apple Silicon (arm64) on the latest macOS.
# Verified end-to-end on macOS 27.0.1 (arm64) with Python 3.13 + py2app 0.28.10.
set -euo pipefail
cd "$(dirname "$0")"

PY="${PY:-python3}"           # use an Apple-Silicon (arm64) python3, e.g. Homebrew
MPV_VERSION="${MPV_VERSION:-v0.41.0}"
MPV_MACOS="${MPV_MACOS:-26}"

# 1. arm64 virtualenv + deps
"$PY" -m venv .venv
.venv/bin/pip install -q -U pip
.venv/bin/pip install -q -r requirements/darwin.txt py2app

# 2. i18n -> .mo
for f in i18n/*; do
  msgfmt -o "$f/LC_MESSAGES/macast.mo" "$f/LC_MESSAGES/macast.po"
done

# 3. official arm64 mpv (replaces the stale x86_64 third-party mirror)
MPV_ZIP="mpv-${MPV_VERSION}-macos-${MPV_MACOS}-arm.zip"
URL="$("$PY" - "$MPV_VERSION" "$MPV_ZIP" <<'EOF'
import sys, json, urllib.request
ver, zname = sys.argv[1], sys.argv[2]
d = json.load(urllib.request.urlopen(
    "https://api.github.com/repos/mpv-player/mpv/releases", timeout=60))
tag = next(x for x in d if x["tag_name"] == ver)
print(next(a["browser_download_url"] for a in tag["assets"] if a["name"] == zname))
EOF
)"
rm -rf bin && mkdir -p bin/MacOS
curl -sL -o /tmp/mpv.zip "$URL"
unzip -q -o /tmp/mpv.zip -d /tmp   # -> /tmp/mpv.tar.gz
tar -xzf /tmp/mpv.tar.gz -C bin --strip-components 2 mpv.app/Contents/MacOS
echo "mpv arch: $(file -b bin/MacOS/mpv)"

# 4. py2app -> thin arm64 app
.venv/bin/python setup_py2app.py py2app --arch=arm64
cp -R bin dist/Macast.app/Contents/Resources/

# 5. ad-hoc sign (use your Developer ID + notarytool for public distribution)
codesign --force --deep --sign - dist/Macast.app
codesign -dv dist/Macast.app

# 6. verify: thin arm64, native-only flags
echo "=== verify ==="
file dist/Macast.app/Contents/MacOS/Macast
lipo -archs dist/Macast.app/Contents/MacOS/Macast
/usr/libexec/PlistBuddy -c "Print" dist/Macast.app/Contents/Info.plist \
  | grep -E "Minimum|Native|Identifier"

# 7. optional DMG
if command -v create-dmg >/dev/null; then
  V=$(cat macast/.version)
  create-dmg --volname "Macast-arm64-v${V} Installer" \
    Macast-MacOS-arm64-v${V}.dmg dist/
fi
echo "Done -> dist/Macast.app"
