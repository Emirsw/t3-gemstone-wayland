#!/usr/bin/env bash
set -euo pipefail

package="${1:?usage: build-ubuntu-source-package.sh <kpipewire|krfb>}"
repo=/repo
meta="$repo/packages/$package/source.lock"
patch_dir="$repo/packages/$package/patches"
work="$repo/sources/$package"
out="$repo/dist"

test -f "$meta"
# shellcheck disable=SC1090
. "$meta"

rm -rf "$work"
mkdir -p "$work" "$out"
cd "$work"

apt-get update
apt-get build-dep -y "$SOURCE_PACKAGE=$UPSTREAM_VERSION"
apt-get source "$SOURCE_PACKAGE=$UPSTREAM_VERSION"

src="$(find . -mindepth 1 -maxdepth 1 -type d | head -n1)"
test -n "$src"
cd "$src"

count="$(find "$patch_dir" -maxdepth 1 -name '*.patch' -type f | wc -l)"
test "$count" -eq "$EXPECTED_PATCHES"
for patch_file in "$patch_dir"/*.patch; do
  patch -p1 --forward <"$patch_file"
done

dch --local "+t3pvr" --distribution noble \
  "T3 Gemstone PowerVR Wayland compatibility patches."

DEB_BUILD_OPTIONS="parallel=${JOBS:-2}" dpkg-buildpackage -b -uc -us
find .. -maxdepth 1 -type f \
  \( -name '*.deb' -o -name '*.buildinfo' -o -name '*.changes' \) \
  -exec cp -f {} "$out/" \;

