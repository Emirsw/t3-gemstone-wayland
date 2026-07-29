#!/usr/bin/env bash
set -euo pipefail

repo=/repo
lock="$repo/packages/mesa-pvr/source.lock"
# shellcheck disable=SC1090
. "$lock"

: "${T3_MESA_SOURCE_URL:?Set T3_MESA_SOURCE_URL to the approved merged Mesa repository}"
: "${T3_MESA_SOURCE_REF:?Set T3_MESA_SOURCE_REF to the approved immutable commit}"

work="$repo/sources/mesa-pvr"
rm -rf "$work"
git clone --filter=blob:none "$T3_MESA_SOURCE_URL" "$work"
cd "$work"
git fetch --depth=1 origin "$T3_MESA_SOURCE_REF"
git checkout --detach FETCH_HEAD

actual="$(git rev-parse HEAD)"
case "$actual" in
  "$T3_VALIDATED_TREE_SHORT"*) ;;
  *)
    echo "Refusing unvalidated Mesa tree: $actual" >&2
    echo "Expected prefix: $T3_VALIDATED_TREE_SHORT" >&2
    exit 2
    ;;
esac

cp "$repo/packages/mesa-pvr/Taskfile.source.yml" Taskfile.yml
task build-deb VERSION="$PACKAGE_VERSION" JOBS="${JOBS:-2}"
mkdir -p "$repo/dist"
cp -f dist/*.deb "$repo/dist/"

