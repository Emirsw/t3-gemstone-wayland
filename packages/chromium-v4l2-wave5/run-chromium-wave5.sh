#!/bin/sh
set -eu

HERE="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"

if [ -f /opt/t3-mesa-pvr-24.0.5/env.sh ]; then
    . /opt/t3-mesa-pvr-24.0.5/env.sh
elif [ -f /opt/t3-mesa-pvr/env.sh ]; then
    . /opt/t3-mesa-pvr/env.sh
fi

exec "$HERE/chrome" \
    --ozone-platform=wayland \
    --use-gl=angle \
    --use-angle=gles \
    --render-node-override=/dev/dri/renderD128 \
    --user-data-dir="$HOME/.config/chromium-t3-wave5" \
    "$@"
