#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="${REPO_ROOT:-$(cd "$script_dir/.." && pwd)}"

# shellcheck disable=SC1091
. "$repo/image/mesa-package.lock"

mkdir -p "$repo/dist"
deb="$repo/dist/$MESA_DEB_NAME"

if [[ ! -f "$deb" ]] ||
   [[ "$(sha256sum "$deb" | awk '{print $1}')" != "$MESA_DEB_SHA256" ]]; then
    rm -f "$deb"
    curl --fail --location --retry 5 --retry-all-errors \
        --output "$deb" "$MESA_DEB_URL"
fi

printf '%s  %s\n' "$MESA_DEB_SHA256" "$deb" | sha256sum --check -
[[ "$(stat -c %s "$deb")" = "$MESA_DEB_SIZE" ]]
[[ "$(dpkg-deb --field "$deb" Package)" = "$MESA_PACKAGE" ]]
[[ "$(dpkg-deb --field "$deb" Version)" = "$MESA_VERSION" ]]
[[ "$(dpkg-deb --field "$deb" Architecture)" = "$MESA_ARCHITECTURE" ]]

echo "Validated Mesa package ready: $deb"
