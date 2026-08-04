#!/usr/bin/env bash
set -euo pipefail

repo=/repo
lock="$repo/packages/mesa-pvr/source.lock"
# shellcheck disable=SC1090
. "$lock"

: "${T3_MESA_SOURCE_URL:?Set T3_MESA_SOURCE_URL to the approved merged Mesa repository}"
: "${T3_MESA_SOURCE_REF:?Set T3_MESA_SOURCE_REF to the approved immutable commit}"

[[ "$T3_MESA_SOURCE_REF" =~ ^[0-9a-f]{40}$ ]] || {
  echo "T3_MESA_SOURCE_REF must be a full 40-character commit." >&2
  exit 2
}

work="$repo/sources/mesa-pvr"
rm -rf "$work"
git clone --filter=blob:none "$T3_MESA_SOURCE_URL" "$work"
cd "$work"
git fetch --depth=1 origin "$T3_MESA_SOURCE_REF"
git checkout --detach FETCH_HEAD

actual="$(git rev-parse HEAD)"
[[ "$actual" = "$T3_MESA_SOURCE_REF" ]] || {
  echo "Refusing unexpected Mesa commit: $actual" >&2
  exit 3
}
[[ "$actual" = "$T3_VALIDATED_TREE_SHORT"* ]] || {
  echo "Refusing unvalidated Mesa tree: $actual" >&2
  echo "Expected validated prefix: $T3_VALIDATED_TREE_SHORT" >&2
  exit 4
}

cp "$repo/packages/mesa-pvr/Taskfile.source.yml" Taskfile.yml
task build-deb VERSION="$PACKAGE_VERSION" JOBS="${JOBS:-2}"
mkdir -p "$repo/dist"
cp -f dist/*.deb "$repo/dist/"

