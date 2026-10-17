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

echo "==> [1/8] compiling translations"
"$PY" "$ROOT/build_tools/po2mo.py"

echo "==> [2/8] fetching mpv $MPV_VERSION (arm64)"
if [ ! -x "$BUILD/mpv/Contents/MacOS/mpv" ]; then
  cd "$BUILD"
  curl -fsSL -o mpv.zip \
    "https://github.com/mpv-player/mpv/releases/download/v${MPV_VERSION}/mpv-v${MPV_VERSION}-macos-15-arm.zip"
  unzip -q -o mpv.zip            # yields mpv.tar.gz
  tar -xzf mpv.tar.gz           # yields mpv.app/

  # Keep mpv's own Contents layout intact. Two things break if we only copy
  # Contents/MacOS:
  #   * the binary and its 97 dylibs, linked via @executable_path/lib
  #   * libMoltenVK.dylib plus the Vulkan ICD manifest, without which the
  #     official build renders nothing:
  #         [vo/gpu-next] Failed initializing any suitable GPU context!
  #     DLNA clients still discover Macast and still get a valid
  #     description.xml, so the only visible symptom is a black screen.
  #
  # The manifest is relocated again after PyInstaller runs -- see below.
  #
  # mv.app itself becomes $BUILD/mpv with its Contents/ kept verbatim, so paths
  # inside the bundle stay identical to upstream.
  rm -rf mpv
  mv mpv.app mpv
fi
lipo -info "$BUILD/mpv/Contents/MacOS/mpv"
[ -f "$BUILD/mpv/Contents/Frameworks/libMoltenVK.dylib" ] ||
  { echo "ERROR: libMoltenVK.dylib missing from mpv bundle" >&2; exit 1; }
[ -f "$BUILD/mpv/Contents/Resources/vulkan/icd.d/MoltenVK_icd.json" ] ||
  { echo "ERROR: MoltenVK ICD manifest missing from mpv bundle" >&2; exit 1; }
echo "    MoltenVK present, Vulkan ICD manifest present"

echo "==> [3/8] running PyInstaller (onedir)"
# mpv lives under Contents/Resources/bin, not Contents/Frameworks. Frameworks
# is a reserved bundle location: codesign --deep treats everything under it as
# nested code, walks mpv's whole Contents tree, and fails verification on
# mpv.conf and icon.icns. Resources is sealed as data instead.
"$PY" -m PyInstaller --noconfirm --onedir -w \
  --additional-hooks-dir="$ROOT" \
  --add-data="$ROOT/macast/.version:." \
  --add-data="$ROOT/macast/xml/*:macast/xml" \
  --add-data="$ROOT/i18n/zh_CN/LC_MESSAGES/*.mo:i18n/zh_CN/LC_MESSAGES" \
  --add-data="$ROOT/macast/assets/*:macast/assets" \
  --add-data="$ROOT/macast/assets/fonts/*:macast/assets/fonts" \
  --add-binary="$BUILD/mpv/Contents/MacOS/mpv:mpvbin/MacOS" \
  --add-binary="$BUILD/mpv/Contents/MacOS/lib/*:mpvbin/MacOS/lib" \
  --add-binary="$BUILD/mpv/Contents/Frameworks/libMoltenVK.dylib:mpvbin/Frameworks" \
  --exclude-module=tkinter \
  --distpath="$PYDIST" \
  --workpath="$BUILD/work" \
  --specpath="$BUILD/spec" \
  --icon="$ROOT/macast/assets/icon.icns" \
  "$ROOT/Macast.py"

# PyInstaller redirects anything named "Resources" into its own Contents/Resources
# and leaves a symlink behind, which would break mpv's Contents layout. Restore
# mpv's tree verbatim.
APP="$PYDIST/Macast.app"
rm -rf "$APP/Contents/Frameworks/mpvbin" "$APP/Contents/Resources/mpvbin"
cp -R "$BUILD/mpv/Contents" "$APP/Contents/Frameworks/mpvbin_contents"
rm -rf "$APP/Contents/Frameworks/mpvbin"
mv "$APP/Contents/Frameworks/mpvbin_contents" "$APP/Contents/Resources/bin"
# Upstream ships these read-only; xattr -cr in the signing step would then fail
# with EPERM on the copied files.
chmod -R u+w "$APP/Contents/Resources/bin"

# The Vulkan loader does NOT look for ICD manifests next to the binary. With
# VK_LOADER_DEBUG=all it prints, in order:
#   DRIVER:  /<bundle>/Contents/Resources/vulkan/icd.d
#   DRIVER:  ~/.config/vulkan/icd.d ... /etc/vulkan/icd.d ... /usr/share/vulkan/icd.d
# i.e. it derives <bundle>/Contents/Resources/vulkan/icd.d from the main
# executable's own path. With mpv parked at Contents/Resources/bin/MacOS/mpv
# that lands on Contents/Resources/vulkan/icd.d -- NOT the
# Contents/Resources/bin/Resources/... copy that came in with mpv.app. The
# bundled manifest is therefore never read, MoltenVK is never loaded, and mpv
# fails every frame with "Failed initializing any suitable GPU context!" while
# still starting normally, still answering IPC and still letting the DLNA
# renderer advertise itself -- which is exactly a device that is discoverable
# and plays nothing.
#
# So publish the manifest where the loader actually looks, and point
# library_path at the MoltenVK we already ship under Contents/Frameworks.
mkdir -p "$APP/Contents/Resources/vulkan/icd.d"
cp "$APP/Contents/Resources/bin/Frameworks/libMoltenVK.dylib" \
   "$APP/Contents/Frameworks/libMoltenVK.dylib"
chmod u+w "$APP/Contents/Frameworks/libMoltenVK.dylib"
cat > "$APP/Contents/Resources/vulkan/icd.d/MoltenVK_icd.json" <<'JSON'
{
    "file_format_version": "1.0.0",
    "ICD": {
        "library_path": "../../../Frameworks/libMoltenVK.dylib",
        "api_version": "1.4.0",
        "is_portability_driver": true
    }
}
JSON
echo "    published MoltenVK ICD manifest to Contents/Resources/vulkan/icd.d"

# PyInstaller mirrors every dylib it finds into the top level of both
# Contents/Frameworks and Contents/Resources as a symlink pointing back into
# the --add-binary destination (mpvbin/...). That destination is gone now, so
# all 194 of those symlinks dangle. They make `xattr -cr` fail with ENOENT and
# they would ship as dead entries pointing at a directory that is not in the
# bundle, so drop every symlink that no longer resolves.
DANGLING=$(find "$APP/Contents" -type l ! -exec test -e {} \; -print 2>/dev/null | wc -l | tr -d ' ')
find "$APP/Contents" -type l ! -exec test -e {} \; -delete 2>/dev/null || true
echo "    removed $DANGLING dangling symlinks left by PyInstaller"

echo "==> [4/8] fixing Info.plist"
# PyInstaller does not read setup_py2app.py's plist dict, so set the keys here.
PB=/usr/libexec/PlistBuddy
plist="$APP/Contents/Info.plist"
add() { $PB -c "Add :$1 $2 $3" "$plist" 2>/dev/null || true; }

add CFBundleIdentifier string cn.xfangfang.Macast
add LSMinimumSystemVersion string 11.0
add LSUIElement bool true
add NSHighResolutionCapable bool true
add NSLocalNetworkUsageDescription string \
  'Macast needs local network access to be discovered and stream media to DLNA devices.'

echo "==> [5/8] signing for arm64"
"$ROOT/build_tools/sign-arm64.sh" "$APP"

echo "==> [6/8] verifying"
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

# The single most important check. The official mpv arm64 build renders through
# Vulkan on MoltenVK, and the loader only finds the ICD manifest at
# Contents/Resources/vulkan/icd.d. If that is wrong, mpv still starts and still
# answers IPC, so every other check passes -- but it cannot open a GPU context
# and the user gets a device that is discoverable and plays nothing at all.
MPV_IN_APP="$APP/Contents/Resources/bin/MacOS/mpv"
[ -x "$MPV_IN_APP" ] || { echo "ERROR: bundled mpv missing" >&2; exit 1; }
[ -f "$APP/Contents/Frameworks/libMoltenVK.dylib" ] ||
  { echo "ERROR: libMoltenVK.dylib not bundled" >&2; exit 1; }
[ -f "$APP/Contents/Resources/vulkan/icd.d/MoltenVK_icd.json" ] ||
  { echo "ERROR: MoltenVK ICD manifest not where the loader looks" >&2; exit 1; }

echo "    checking mpv can open a GPU context"
MPV_OUT="$(cd / && "$MPV_IN_APP" --no-config --vo=gpu-next --frames=1 \
  "av://lavfi:testsrc=size=320x240:rate=1:duration=1" 2>&1)" || true
if echo "$MPV_OUT" | grep -q "Failed initializing any suitable GPU context"; then
  echo "ERROR: bundled mpv cannot create a GPU context:" >&2
  echo "$MPV_OUT" | sed 's/^/      /' >&2
  exit 1
fi
echo "    mpv GPU context OK"

# Second-most-important check: the window has to be *visible*.
#
# --ontop-level=system puts mpv's window on kCGDesktopWindowLevel (CG layer 26),
# underneath the desktop icons and wallpaper. Nothing else changes: the window
# exists, has the right size, reports onscreen=YES, and playback runs with
# vo-configured=true. Only the user sees nothing at all. So ask the window
# server where the window ended up, using the exact flags macast_renderer/mpv.py
# passes, and fail the build if it sank below the normal window layer.
echo "    checking mpv window is on a visible layer"
WINDOW_CHECK="$("$PY" - "$MPV_IN_APP" <<'PYEOF'
import subprocess, sys, time, signal
mpv = sys.argv[1]
try:
    import Quartz
except ImportError:
    print("SKIP: pyobjc Quartz unavailable")
    sys.exit(0)
p = subprocess.Popen(
    [mpv, "--no-config", "--idle=yes", "--no-terminal", "--keep-open=yes",
     "--force-window=yes", "--vo=gpu-next",
     "--ontop", "--on-all-workspaces",
     "--macos-app-activation-policy=accessory",
     "av://lavfi:testsrc=size=320x240:rate=10:duration=2"],
    stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
worst = None
try:
    for _ in range(20):
        time.sleep(0.5)
        wl = Quartz.CGWindowListCopyWindowInfo(
            Quartz.kCGWindowListOptionAll, Quartz.kCGNullWindowID)
        for w in wl:
            b = w.get("kCGWindowBounds") or {}
            if w.get("kCGWindowOwnerPID") == p.pid and b.get("Width", 0) > 100:
                worst = int(w.get("kCGWindowLayer", -1))
                break
        if worst is not None:
            break
finally:
    p.send_signal(signal.SIGKILL)
    p.wait()
if worst is None:
    print("NOWINDOW")
else:
    print(worst)
PYEOF
)"
WINDOW_LAYER=$(echo "$WINDOW_CHECK" | tail -1)
case "$WINDOW_CHECK" in
  SKIP*) echo "    $WINDOW_CHECK" ;;
  NOWINDOW)
    echo "ERROR: mpv opened no window at all (video would never be seen)" >&2
    exit 1 ;;
  *)
    # 0 = normal, 3 = floating. Anything >= 24 means desktop-level or lower,
    # which is behind the wallpaper.
    if [ "$WINDOW_LAYER" -ge 24 ]; then
      echo "ERROR: mpv window landed on CG layer $WINDOW_LAYER" >&2
      echo "       Layers >= 24 sit under the desktop icons and wallpaper, so" >&2
      echo "       playback runs but the user sees nothing." >&2
      echo "       Check for --ontop-level=system in macast_renderer/mpv.py." >&2
      exit 1
    fi
    echo "    mpv window on CG layer $WINDOW_LAYER (visible)" ;;
esac

echo "==> [7/8] building DMG"
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