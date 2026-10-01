#!/usr/bin/env bash
# Local IPA build, kept for the old command. The pipeline itself lives in
# Scripts/build-merged-ipa.sh — the flags table, make package, the Live Activity appex, cyan,
# zxPluginsInject, App Intents metadata, the alternate app icons and the verification — and this
# wrapper just runs all of it, then drops the result where this script's outputs always landed.
#
#   ./build-ipa-local.sh <vanilla Spotify.ipa>
#
# Replaces the six-step pipeline that used to live here: it had drifted out of the build (no
# flags table, no Live Activity appex, no App Intents merge, no icons) and mirrored a workflow
# (main.yml) that no longer exists.

set -euo pipefail

VANILLA_IPA="${1:-}"
[ -n "$VANILLA_IPA" ] && [ -f "$VANILLA_IPA" ] || {
    echo "usage: $0 <path/to/Spotify-vanilla.ipa>" >&2
    exit 1
}

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The merged pipeline prints its own nine steps; this only keeps the output naming this entry
# point always had: Outputs/IPAS/EeveeSpotify-<tweak version>-<Spotify version>.ipa.
VERSION=$(grep -E '^Version:' "$REPO_DIR/control" | awk '{print $2}')
SPOT_VERSION=$(unzip -p "$VANILLA_IPA" 'Payload/Spotify.app/Info.plist' \
    | plutil -extract CFBundleShortVersionString raw - 2>/dev/null || echo "unknown")

exec "$REPO_DIR/Scripts/build-merged-ipa.sh" "$VANILLA_IPA" \
    "$REPO_DIR/Outputs/IPAS/EeveeSpotify-${VERSION}-${SPOT_VERSION}.ipa"
