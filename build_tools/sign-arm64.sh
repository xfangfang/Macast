#!/bin/bash
# Ad-hoc sign a PyInstaller onedir bundle for Apple Silicon.
#
# Two problems this solves:
#
# 1. PyInstaller drops the whole Python runtime into Contents/Frameworks,
#    mixing Mach-O files with plain stdlib sources (__future__.py, os.pyc,
#    dist-info/...). codesign treats everything under Frameworks as a nested
#    code component and verification fails on the first .py it meets with
#    "code object is not signed at all". We relocate the inert files into
#    Contents/Resources, where codesign only inspects declared nested-code
#    slots. Runtime lookup is path-based off Contents/, so nothing breaks.
#
# 2. arm64 + hardened runtime enforces library validation: every loaded image
#    must share the main executable's Team ID. Ad-hoc signatures carry no Team
#    ID at all, so libpython3.13.dylib is refused with "mapping process and
#    mapped file have different Team IDs". The entitlements below disable
#    library validation, which is exactly what a self-built Python app needs.
#
# Usage: ./sign-arm64.sh /path/to/Macast.app
set -euo pipefail

APP="${1:?usage: sign-arm64.sh <path/to/App.app>}"
FW="$APP/Contents/Frameworks"
RES="$APP/Contents/Resources"
HERE="$(cd "$(dirname "$0")" && pwd)"
ENT="$HERE/entitlements.plist"

[ -d "$APP" ] || { echo "not a bundle: $APP" >&2; exit 1; }

echo "    clearing previous signatures"
codesign --remove-signature "$APP" 2>/dev/null || true
rm -rf "$APP/Contents/_CodeSignature"

if [ -d "$FW" ]; then
  echo "    relocating non-Mach-O files out of Frameworks"
  MOVED=0
  while IFS= read -r -d '' f; do
    rel="${f#"$FW"/}"
    dest="$RES/$rel"
    mkdir -p "$(dirname "$dest")"
    mv "$f" "$dest"
    MOVED=$((MOVED + 1))
  done < <(find "$FW" -type f ! -name "*.so" ! -name "*.dylib" -print0 2>/dev/null)
  echo "    moved $MOVED files"
  find "$FW" -type d -empty -delete 2>/dev/null || true
fi

echo "    signing Mach-O files (deepest first)"
# mpv and its 97 dylibs live under Contents/Resources, which codesign seals as
# data rather than nested code, so they are signed here explicitly to satisfy
# arm64's "no unsigned Mach-O" rule.
find "$APP/Contents" -type f \( -name "*.so" -o -name "*.dylib" \) 2>/dev/null |
  sort -r |
  while IFS= read -r f; do
    codesign --force --sign - "$f" 2>/dev/null || true
  done

echo "    signing executable and bundle with entitlements"
codesign --force --sign - --entitlements "$ENT" "$APP/Contents/MacOS/Macast"
# --deep lets codesign reach nested code through the bundle's recorded
# CodeResources. Everything Mach-O has already been signed above; the data
# files inside mpv's tree (icon.icns, the Vulkan ICD json) are covered by the
# resource seal instead of needing individual signatures.
codesign --force --deep --sign - --entitlements "$ENT" --options runtime "$APP"

# Quarantine and download-origin flags have to go, but xattr exits non-zero if
# it meets a single unreadable entry and `set -e` would abort a build whose
# bundle is otherwise fine. codesign --verify right below is the real gate.
xattr -cr "$APP" 2>/dev/null || true
codesign --verify --verbose=1 "$APP"
echo "    signed: $(codesign -dv "$APP" 2>&1 | grep 'Format=' | sed 's/.*Format=//')"