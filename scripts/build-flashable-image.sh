#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="${REPO_ROOT:-$(cd "$script_dir/.." && pwd)}"
lock="$repo/image/source.lock"
dist="$repo/dist"
work="$repo/build/image"
root="$work/root"

# shellcheck disable=SC1090
. "$lock"

version="${IMAGE_VERSION:-$(date -u +%Y%m%d)-${GITHUB_SHA:-local}}"
version="${version:0:32}"
output_base="t3-gemstone-wayland-${version}-arm64"
download="$work/$BASE_IMAGE_NAME"
raw="$work/$output_base.img"
output="$dist/$output_base.img.xz"
manifest="$dist/$output_base.manifest.txt"

for command in curl sha256sum xz losetup mount umount chroot growpart blkid; do
    command -v "$command" >/dev/null || {
        echo "Required command is missing: $command" >&2
        exit 2
    }
done

mapfile -t debs < <(find "$dist" -maxdepth 1 -type f -name '*.deb' -print | sort)
((${#debs[@]} > 0)) || {
    echo "No Debian packages found in $dist" >&2
    exit 3
}
printf '%s\n' "${debs[@]}" | grep -q '/t3-mesa-pvr-2405-test_' || {
    echo "The validated t3-mesa-pvr-2405-test package is required." >&2
    exit 4
}

mkdir -p "$work" "$root" "$dist"
if [[ ! -f "$download" ]] ||
   [[ "$(sha256sum "$download" | awk '{print $1}')" != "$BASE_IMAGE_DOWNLOAD_SHA256" ]]; then
    rm -f "$download"
    curl --fail --location --retry 5 --retry-all-errors \
        --output "$download" "$BASE_IMAGE_URL"
fi
printf '%s  %s\n' "$BASE_IMAGE_DOWNLOAD_SHA256" "$download" | sha256sum --check -
[[ "$(stat -c %s "$download")" = "$BASE_IMAGE_DOWNLOAD_SIZE" ]] ||
    { echo "Compressed image size mismatch" >&2; exit 5; }

rm -f "$raw"
xz --decompress --stdout "$download" >"$raw"
printf '%s  %s\n' "$BASE_IMAGE_EXTRACT_SHA256" "$raw" | sha256sum --check -
[[ "$(stat -c %s "$raw")" = "$BASE_IMAGE_EXTRACT_SIZE" ]] ||
    { echo "Extracted image size mismatch" >&2; exit 6; }

# The official minimal image is intentionally only 1 GB. Plasma and its
# dependencies need more room while being installed. The zero-filled growth
# compresses efficiently and leaves a directly flashable 8 GiB image.
truncate -s "${IMAGE_SIZE:-8G}" "$raw"

loop=""
mounted=()
cleanup() {
    set +e
    for ((index=${#mounted[@]}-1; index>=0; index--)); do
        mountpoint -q "${mounted[$index]}" && umount "${mounted[$index]}"
    done
    [[ -n "$loop" ]] && losetup -d "$loop" 2>/dev/null
}
trap cleanup EXIT

loop="$(losetup --find --show --partscan "$raw")"
root_partition="${loop}p2"
boot_partition="${loop}p1"
for attempt in {1..20}; do
    [[ -b "$root_partition" ]] && break
    sleep 0.25
done
[[ -b "$root_partition" ]] ||
    { echo "Root partition not found: $root_partition" >&2; exit 7; }

growpart "$loop" 2
partprobe "$loop"
filesystem_type="$(blkid -o value -s TYPE "$root_partition")"
if [[ "$filesystem_type" = ext4 ]]; then
    e2fsck -pf "$root_partition" || [[ $? = 1 ]]
    resize2fs "$root_partition"
fi

mount "$root_partition" "$root"
mounted+=("$root")
if [[ "$filesystem_type" = btrfs ]]; then
    btrfs filesystem resize max "$root"
fi
if [[ -b "$boot_partition" ]]; then
    mkdir -p "$root/boot"
    mount "$boot_partition" "$root/boot"
    mounted+=("$root/boot")
fi
for filesystem in dev dev/pts proc sys run; do
    mkdir -p "$root/$filesystem"
    mount --rbind "/$filesystem" "$root/$filesystem"
    mount --make-rslave "$root/$filesystem"
    mounted+=("$root/$filesystem")
done

mkdir -p "$root/tmp/t3-debs" "$root/etc/t3-gemstone-image"
cp -f "${debs[@]}" "$root/tmp/t3-debs/"
cp -f /usr/bin/qemu-aarch64-static "$root/usr/bin/qemu-aarch64-static"

resolv_link=""
if [[ -L "$root/etc/resolv.conf" ]]; then
    resolv_link="$(readlink "$root/etc/resolv.conf")"
fi
rm -f "$root/etc/resolv.conf"
cp -L /etc/resolv.conf "$root/etc/resolv.conf"
cat >"$root/usr/sbin/policy-rc.d" <<'EOF'
#!/bin/sh
exit 101
EOF
chmod 0755 "$root/usr/sbin/policy-rc.d"
cat >"$root/tmp/t3-image-install.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y --no-install-recommends /tmp/t3-debs/*.deb
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/t3-debs
systemctl enable sddm.service
EOF
chmod 0755 "$root/tmp/t3-image-install.sh"
chroot "$root" /usr/bin/qemu-aarch64-static /bin/bash /tmp/t3-image-install.sh

{
    echo "image_version=$version"
    echo "base_image=$BASE_IMAGE_NAME"
    echo "base_image_url=$BASE_IMAGE_URL"
    echo "base_image_sha256=$BASE_IMAGE_DOWNLOAD_SHA256"
    echo "source_commit=${GITHUB_SHA:-local}"
    echo
    for deb in "${debs[@]}"; do
        dpkg-deb --show "$deb" --showformat='${Package}\t${Version}\t${Architecture}\n'
    done
} | tee "$root/etc/t3-gemstone-image/manifest.txt" >"$manifest"

rm -f "$root/usr/bin/qemu-aarch64-static" \
    "$root/usr/sbin/policy-rc.d" "$root/tmp/t3-image-install.sh"
truncate -s 0 "$root/etc/machine-id" 2>/dev/null || true
if [[ -n "$resolv_link" ]]; then
    rm -f "$root/etc/resolv.conf"
    ln -s "$resolv_link" "$root/etc/resolv.conf"
fi
sync
cleanup
trap - EXIT
loop=""
mounted=()

rm -f "$output"
xz --threads=0 --compress --stdout -6 "$raw" >"$output"
sha256sum "$output" >"$output.sha256"
echo "Flashable image ready: $output"
ls -lh "$output" "$output.sha256" "$manifest"
