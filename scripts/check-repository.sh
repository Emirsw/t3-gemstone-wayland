#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${repo_root}"
required=(
  Taskfile.yml
  docker/Dockerfile
  packages/mesa-pvr/source.lock
  packages/kpipewire/source.lock
  packages/krfb/source.lock
  packages/kpipewire/patches/0001-t3-pvr-add-opt-in-shm-capture.patch
  packages/krfb/patches/0001-t3-pvr-correct-inverted-pipewire-frames.patch
  packages/krfb/patches/0002-t3-pvr-copy-damaged-rows-directly.patch
  packages/krfb/patches/0003-t3-pvr-enable-pipewire-damage-tracking.patch
)

for file in "${required[@]}"; do
  test -f "$file" || { echo "Missing required file: $file" >&2; exit 1; }
done

executable_scripts=(
  scripts/build-ubuntu-source-package.sh
  scripts/check-repository.sh
)

for script in "${executable_scripts[@]}"; do
  mode="$(git ls-files --stage -- "$script" | awk '{print $1}')"
  test "$mode" = "100755" || {
    echo "Script is not executable in Git: $script (mode ${mode:-missing})" >&2
    exit 3
  }
done

if find . -type f \( -name '*.deb' -o -name '*.key' -o -name '*.pem' \) \
  -not -path './dist/*' | grep -q .; then
  echo "Generated package or secret-like file found outside dist/" >&2
  exit 2
fi

test "$(find packages/kpipewire/patches -name '*.patch' | wc -l)" -eq 1
test "$(find packages/krfb/patches -name '*.patch' | wc -l)" -eq 3
echo "Repository structure: OK"
