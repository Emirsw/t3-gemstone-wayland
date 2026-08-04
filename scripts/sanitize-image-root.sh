#!/usr/bin/env bash
set -euo pipefail

root="${1:?usage: sanitize-image-root.sh ROOT}"
[[ -d "$root/etc" ]] || { echo "Invalid image root: $root" >&2; exit 2; }

# Remove identities and state which must be generated independently on first boot.
rm -f "$root"/etc/ssh/ssh_host_* 2>/dev/null || true
truncate -s 0 "$root/etc/machine-id"
rm -f "$root/var/lib/dbus/machine-id"
ln -s /etc/machine-id "$root/var/lib/dbus/machine-id"
rm -f "$root/var/lib/systemd/random-seed"

# Never publish credentials, network profiles, shell history or remote-desktop secrets.
rm -rf "$root/etc/NetworkManager/system-connections"/* 2>/dev/null || true
rm -rf "$root/etc/wpa_supplicant"/*.conf 2>/dev/null || true
rm -f "$root/root/.bash_history" "$root/root/.python_history"
find "$root/home" -xdev -type f \( \
    -name '.bash_history' -o -name '.python_history' -o \
    -name 'authorized_keys' -o -name 'known_hosts' -o \
    -name '*.pem' -o -name '*.key' \
  \) -delete 2>/dev/null || true
find "$root/home" -xdev -type d \( \
    -path '*/.local/share/Trash' -o -path '*/.cache' -o \
    -path '*/.config/kwalletd' \
  \) -prune -exec rm -rf {} + 2>/dev/null || true
find "$root/home" -xdev -type f -path '*/.local/share/recently-used.xbel' \
  -delete 2>/dev/null || true
find "$root/home" -xdev -type f \( -name 'krfbrc' -o -name 'kdeglobals.lock' \) \
  -delete 2>/dev/null || true

# Logs and package caches are build-time state, not product content.
find "$root/var/log" -xdev -type f -exec truncate -s 0 {} + 2>/dev/null || true
rm -rf "$root/var/log/journal"/* "$root/var/tmp"/* "$root/tmp"/*
rm -rf "$root/var/cache/apt/archives"/* "$root/var/lib/apt/lists"/*

if [[ -x "$root/usr/bin/cloud-init" ]]; then
  chroot "$root" /usr/bin/cloud-init clean --logs --seed || true
fi

sync
