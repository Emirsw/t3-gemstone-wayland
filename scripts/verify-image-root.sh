#!/usr/bin/env bash
set -euo pipefail

root="${1:?usage: verify-image-root.sh ROOT BOOT_ALLOWLIST}"
allowlist="${2:?usage: verify-image-root.sh ROOT BOOT_ALLOWLIST}"

actual="$(mktemp)"
expected="$(mktemp)"
trap 'rm -f "$actual" "$expected"' EXIT

find "$root/boot" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort >"$actual"
LC_ALL=C sort -u "$allowlist" >"$expected"
if ! diff -u "$expected" "$actual"; then
  echo "Boot partition contains missing or unexpected top-level entries." >&2
  exit 2
fi

[[ ! -s "$root/etc/machine-id" ]] || {
  echo "machine-id was not reset" >&2
  exit 3
}
[[ ! -e "$root/var/lib/systemd/random-seed" ]] || {
  echo "systemd random seed was not removed" >&2
  exit 4
}
if find "$root/etc/NetworkManager/system-connections" -type f -print -quit \
    2>/dev/null | grep -q .; then
  echo "A NetworkManager connection profile remains in the image." >&2
  exit 5
fi
if find "$root/home" -xdev -type f \( \
    -name 'authorized_keys' -o -name 'known_hosts' -o \
    -name '.bash_history' -o -name '*.pem' -o -name '*.key' \
  \) -print -quit 2>/dev/null | grep -q .; then
  echo "A personal credential or history file remains in /home." >&2
  exit 6
fi

for required in \
  "$root/usr/bin/kwin_wayland" \
  "$root/usr/bin/plasmashell" \
  "$root/opt/t3-mesa-pvr-24.0.5/env.sh"; do
  [[ -e "$required" ]] || { echo "Required runtime missing: $required" >&2; exit 7; }
done

echo "Image root and boot partition: OK"
