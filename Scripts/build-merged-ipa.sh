#!/usr/bin/env bash
# Builds the merged tweak and puts it, its framework, its bundle and the Live Activity widget
# extension into a decrypted Spotify IPA.
#
#   Scripts/build-merged-ipa.sh <decrypted Spotify.ipa> [out.ipa]
#
# Default output is out/EeveeSpotify-Merged.ipa. The IPA is left unsigned: sign it with Sideloadly,
# AltStore or any certificate signer.
#
# Note on the widget: it cannot ride in the .deb. A WidgetKit extension is a separate process that
# WidgetKit only launches from inside the host app's bundle, so an appex under /Library has nothing
# to launch it. spoti.pw put it in the IPA for the same reason, and so does this — one pipeline, one
# output IPA, which is the part that matters. Everything else still comes out of the .deb.
set -euo pipefail

IPA="${1:?usage: $0 <decrypted Spotify.ipa> [out.ipa]}"
[ -f "$IPA" ] || { echo "no such IPA: $IPA" >&2; exit 1; }
OUT_IPA="${2:-}"

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_DIR"

[ -n "${THEOS:-}" ] || { [ -d "$HOME/theos" ] && export THEOS="$HOME/theos" || { echo "THEOS not set"; exit 1; }; }
export THEOS

for tool in cyan dpkg-deb plutil unzip zip; do
    command -v "$tool" >/dev/null || { echo "missing tool: $tool" >&2; exit 1; }
done

VERSION=$(grep -E '^Version:' control | awk '{print $2}')
[ -n "$OUT_IPA" ] || OUT_IPA="$REPO_DIR/out/EeveeSpotify-Merged.ipa"
# Absolute from here on: cyan and ipapatch both take it as given, and the appex step runs from
# inside a staging directory where a relative path would point at nothing.
case "$OUT_IPA" in /*) ;; *) OUT_IPA="$REPO_DIR/$OUT_IPA" ;; esac
mkdir -p "$(dirname "$OUT_IPA")"

color() { printf '\033[1;32m==> %s\033[0m\n' "$*"; }

# The flags table is generated, not committed: without it the link has no EeveeFlagTable.
if [ ! -f Sources/EeveeSpotifyC/Shared/Flags/EeveeFlagList.m ]; then
    color "0/8  flags table from the IPA"
    python3 Scripts/extract-flags.py "$IPA"
fi

color "1/8  libjamesdsp + theos make package"
make -C modules/libjamesdsp JDSP_PLATFORM=ios >/dev/null
make package FINALPACKAGE=1 THEOS_PACKAGE_SCHEME=rootless >/dev/null
DEB_FILE=$(ls -t packages/com.eevee.spotify_*.deb 2>/dev/null | head -1)
[ -n "$DEB_FILE" ] || { echo "deb not produced" >&2; exit 1; }

color "2/8  extract the deb"
DEB_EXTRACT="$REPO_DIR/out/deb-extract"
rm -rf "$DEB_EXTRACT"; mkdir -p "$DEB_EXTRACT"
dpkg-deb -R "$DEB_FILE" "$DEB_EXTRACT"
DYLIB_SRC=$(find "$DEB_EXTRACT" -name 'EeveeSpotify.dylib' | head -1)
BUNDLE_SRC=$(find "$DEB_EXTRACT" -type d -name 'EeveeSpotify.bundle' | head -1)
FRAMEWORK_SRC=$(find "$DEB_EXTRACT" -type d -name 'EeveeSwiftProtobuf.framework' | head -1)
[ -n "$DYLIB_SRC" ] || { echo "EeveeSpotify.dylib not in the deb" >&2; exit 1; }

color "3/8  Live Activity appex"
chmod +x Scripts/build-liveactivity.sh
HOST_PLIST="$REPO_DIR/out/host-Info.plist"
unzip -p "$IPA" 'Payload/Spotify.app/Info.plist' > "$HOST_PLIST"
Scripts/build-liveactivity.sh "$HOST_PLIST" "$REPO_DIR/out/liveactivity"
APPEX="$REPO_DIR/out/liveactivity/EeveeSpotifyLiveActivity.appex"

color "4/8  cyan inject the tweak"
INJECT=("$DYLIB_SRC")
[ -n "$FRAMEWORK_SRC" ] && INJECT+=("$FRAMEWORK_SRC")
[ -n "$BUNDLE_SRC" ]    && INJECT+=("$BUNDLE_SRC")
rm -f "$OUT_IPA"
# -m 16.0 matches the tweak's own deployment target (see the Makefile): it uses iOS 15+/26 API and
# links a libjamesdsp built for ios16.0, so a lower floor would only promise a load that cannot work.
cyan -i "$IPA" -o "$OUT_IPA" -f "${INJECT[@]}" -c 9 -m 16.0 -du

color "5/8  zxPluginsInject (sideload: keychain redirect, group containers, CloudKit)"
if [ -x Tools/build-zxpi.sh ]; then
    Tools/build-zxpi.sh >/dev/null
    ipapatch --input "$OUT_IPA" --inplace --noconfirm --dylib packages/zxPluginsInject.dylib
else
    echo "    Tools/build-zxpi.sh not executable; skipping (sideload-only shim)"
fi

color "6/8  put the appex in the app"
STAGE="$REPO_DIR/out/ipa-stage"
rm -rf "$STAGE"; mkdir -p "$STAGE/Payload/Spotify.app/PlugIns"
cp -R "$APPEX" "$STAGE/Payload/Spotify.app/PlugIns/"
( cd "$STAGE" && zip -qry "$OUT_IPA" Payload/Spotify.app/PlugIns )

color "7/8  App Intents metadata into Spotify's own"
# The processor writes <bundle>/Metadata.appintents; merge-appintents.py wants that directory
# itself, since it reads extract.actionsdata and version.json out of it.
python3 Scripts/merge-appintents.py "$OUT_IPA" 'Payload/Spotify.app/' \
    "$REPO_DIR/out/liveactivity/app/Metadata.appintents"

color "8/8  verify"
# The listing goes to a file rather than down a pipe: with `set -o pipefail`, `grep -q` exits on its
# first match, the writer takes SIGPIPE, and the pipeline reads as a failure even when the match was
# found. (Which is exactly how this step first reported a missing appex that was there all along.)
LIST="$REPO_DIR/out/ipa-contents.txt"
unzip -l "$OUT_IPA" > "$LIST"
for entry in \
    'Payload/Spotify.app/PlugIns/EeveeSpotifyLiveActivity.appex/EeveeSpotifyLiveActivity' \
    'Payload/Spotify.app/PlugIns/EeveeSpotifyLiveActivity.appex/Info.plist' \
    'Payload/Spotify.app/Frameworks/EeveeSpotify.dylib' \
    'Payload/Spotify.app/Metadata.appintents/extract.actionsdata'
do
    grep -qF "$entry" "$LIST" || { echo "missing from the IPA: $entry" >&2; exit 1; }
    echo "    ok  $entry"
done
APPEX_ACTIONS=$(unzip -p "$OUT_IPA" 'Payload/Spotify.app/Metadata.appintents/extract.actionsdata' | python3 -c 'import json,sys; print(len(json.load(sys.stdin)["actions"]))')
echo "    ok  Spotify's App Intents metadata names $APPEX_ACTIONS actions"
rm -rf "$STAGE" "$DEB_EXTRACT" "$LIST"

color "Done — $OUT_IPA"
ls -lh "$OUT_IPA"
echo "Unsigned. Sign with Sideloadly / AltStore / TrollStore."
