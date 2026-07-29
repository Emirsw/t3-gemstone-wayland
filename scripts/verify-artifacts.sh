#!/usr/bin/env bash
set -euo pipefail

cd /repo
mkdir -p dist
shopt -s nullglob
debs=(dist/*.deb)
if ((${#debs[@]} == 0)); then
  echo "No Debian artifacts found in dist/" >&2
  exit 1
fi

: >dist/SHA256SUMS
for deb in "${debs[@]}"; do
  dpkg-deb --info "$deb" >/dev/null
  arch="$(dpkg-deb -f "$deb" Architecture)"
  case "$arch" in arm64|all) ;; *) echo "Unexpected architecture $arch: $deb" >&2; exit 2;; esac
  sha256sum "$deb" >>dist/SHA256SUMS
done
sha256sum -c dist/SHA256SUMS

