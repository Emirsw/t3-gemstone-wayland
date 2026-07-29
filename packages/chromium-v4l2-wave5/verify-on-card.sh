#!/usr/bin/env bash
set -euo pipefail

echo "=== WAVE5 ==="
v4l2-ctl --list-devices
gst-inspect-1.0 v4l2h264dec |
  grep -E 'Rank|Long-name|Klass'

echo
echo "=== CHROMIUM /DEV/VIDEO ERISIMI ==="
found=0
for pid in $(pgrep -u "$USER" -f '/chrome|chromium'); do
    while IFS= read -r line; do
        printf 'PID=%s %s\n' "$pid" "$line"
        found=1
    done < <(sudo ls -l "/proc/$pid/fd" 2>/dev/null |
      grep -E '/dev/video[0-9]+' || true)
done

if [ "$found" -eq 0 ]; then
    echo "VPU_ACILMADI"
    exit 1
fi

echo "VPU_ACILDI"
echo "chrome://media-internals -> video_decoder degeri GpuVideoDecoder olmali."

