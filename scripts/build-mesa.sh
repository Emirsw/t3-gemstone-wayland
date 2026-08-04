#!/usr/bin/env bash
set -euo pipefail

repo=/repo
lock="$repo/packages/mesa-pvr/source.lock"
# shellcheck disable=SC1090
. "$lock"

work="$repo/sources/mesa-pvr"
rm -rf "$work"
git clone --filter=blob:none --no-checkout "$STATICROCKET_URL" "$work"
cd "$work"
git fetch --depth=1 origin "$STATICROCKET_COMMIT"
git checkout --detach "$STATICROCKET_COMMIT"
git remote add upstream "$MESA_UPSTREAM_URL"
git fetch --depth=1 upstream "$MESA_UPSTREAM_COMMIT"

set +e
git -c user.name='T3 Gemstone Build' \
    -c user.email='wayland@t3gemstone.org' \
    merge --no-commit --no-ff --allow-unrelated-histories \
    "$MESA_UPSTREAM_COMMIT"
merge_status=$?
set -e
[[ "$merge_status" = 1 ]] || {
  echo "Expected the validated single Mesa merge conflict, got status $merge_status" >&2
  exit 2
}

mapfile -t unresolved < <(git diff --name-only --diff-filter=U)
[[ "${#unresolved[@]}" = 1 && \
   "${unresolved[0]}" = src/egl/drivers/dri2/platform_wayland.c ]] || {
  printf 'Unexpected Mesa conflicts:\n%s\n' "${unresolved[*]:-none}" >&2
  exit 3
}
git checkout --theirs -- src/egl/drivers/dri2/platform_wayland.c
git add src/egl/drivers/dri2/platform_wayland.c

actual_tree="$(git write-tree)"
[[ "$actual_tree" = "$T3_MERGED_TREE" ]] || {
  echo "Refusing unvalidated merged Mesa tree: $actual_tree" >&2
  echo "Expected: $T3_MERGED_TREE" >&2
  exit 4
}

cp "$repo/packages/mesa-pvr/Taskfile.source.yml" Taskfile.yml
task build-deb VERSION="$PACKAGE_VERSION" JOBS="${JOBS:-2}"
mkdir -p "$repo/dist"
cp -f dist/*.deb "$repo/dist/"

