#!/usr/bin/env bash
set -euo pipefail

SRC="${CHROMIUM_SRC:-/work/chromium/src}"
OUT="${CHROMIUM_OUT:-out/t3gem-arm64-v4l2}"
DEST="${DEST:-/work/chromium-152-t3gem-o1-v4l2}"
ARCHIVE="${ARCHIVE:-${DEST}.tar.gz}"

rm -rf "$DEST"
mkdir -p "$DEST/locales"

cp "$SRC/$OUT/chrome" "$DEST/"
cp "$SRC/$OUT/chrome-sandbox" "$DEST/" 2>/dev/null || true
cp "$SRC/$OUT/chrome_crashpad_handler" "$DEST/" 2>/dev/null || true
cp "$SRC/$OUT/icudtl.dat" "$DEST/"
cp "$SRC/$OUT/resources.pak" "$DEST/"
cp "$SRC/$OUT/chrome_100_percent.pak" "$DEST/" 2>/dev/null || true
cp "$SRC/$OUT/chrome_200_percent.pak" "$DEST/" 2>/dev/null || true
cp "$SRC/$OUT/v8_context_snapshot.bin" "$DEST/" 2>/dev/null || true
cp "$SRC/$OUT/snapshot_blob.bin" "$DEST/" 2>/dev/null || true
cp "$SRC/$OUT/locales/en-US.pak" "$DEST/locales/"
cp "$SRC/$OUT/locales/tr.pak" "$DEST/locales/" 2>/dev/null || true
cp "$(dirname "$0")/run-chromium-wave5.sh" "$DEST/"

tar -C "$(dirname "$DEST")" -czf "$ARCHIVE" "$(basename "$DEST")"
sha256sum "$ARCHIVE" | tee "$ARCHIVE.sha256"
ls -lh "$ARCHIVE"

