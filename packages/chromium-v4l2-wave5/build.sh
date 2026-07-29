#!/usr/bin/env bash
set -euo pipefail

SRC="${CHROMIUM_SRC:-/work/chromium/src}"
OUT="${CHROMIUM_OUT:-out/t3gem-arm64-v4l2}"
JOBS="${JOBS:-$(nproc)}"
ROOT="$(cd "$(dirname "$0")" && pwd)"

cd "$SRC"

if [ "${APPLY_TI_PATCHES:-1}" = "1" ]; then
    CHROMIUM_SRC="$SRC" "$ROOT/apply-ti-patches.sh"
fi

mkdir -p "$OUT"
cp "$ROOT/args.gn" "$OUT/args.gn"

gn gen "$OUT"

echo "=== ETKIN GN AYARLARI ==="
gn args "$OUT" --list |
  grep -E '^(target_cpu|use_v4l2_codec|use_v4lplugin|use_vaapi|proprietary_codecs|ffmpeg_branding|ozone_platform_wayland) ' ||
  true

autoninja -C "$OUT" -j "$JOBS" chrome

echo "Derleme tamamlandi: $SRC/$OUT/chrome"
