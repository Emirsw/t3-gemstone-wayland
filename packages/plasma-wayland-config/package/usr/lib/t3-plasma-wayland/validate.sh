#!/bin/bash
set -u

export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export DBUS_SESSION_BUS_ADDRESS="${DBUS_SESSION_BUS_ADDRESS:-unix:path=${XDG_RUNTIME_DIR}/bus}"

echo "=== OTURUM ==="
for sid in $(loginctl list-sessions --no-legend | awk -v uid="$(id -u)" '$2 == uid {print $1}'); do
    loginctl show-session "${sid}" \
        -p Name \
        -p Remote \
        -p Type \
        -p Desktop \
        -p State \
        -p Seat \
        -p VTNr
done

echo
echo "=== GRAFIK SURECLERI ==="
pgrep -a -u "$(id -u)" -f 'kwin_wayland|plasmashell|Xwayland|krfb' || true

echo
echo "=== SERVISLER ==="
systemctl --user show \
    plasma-kwin_wayland.service \
    plasma-plasmashell.service \
    plasma-xdg-desktop-portal-kde.service \
    t3-krfb-wayland.service \
    -p Id \
    -p ActiveState \
    -p SubState \
    -p Result \
    -p NRestarts

echo
echo "=== KWIN RENDERER ==="
if command -v qdbus >/dev/null 2>&1; then
    qdbus org.kde.KWin /KWin supportInformation 2>/dev/null |
        grep -E \
            'Compositing Type|OpenGL vendor string|OpenGL renderer string|OpenGL version string|OpenGL platform interface' |
        head -n 20
fi

echo
echo "=== BELLEK ==="
free -h
grep -E '^(MemTotal|MemAvailable|CmaTotal|CmaFree):' /proc/meminfo
echo
echo "=== DUSUK RAM PROFILI ==="
for unit in \
    plasma-gmenudbusmenuproxy.service \
    plasma-xembedsniproxy.service \
    app-kaccess@autostart.service \
    at-spi-dbus-bus.service \
    xdg-desktop-portal-gtk.service \
    filter-chain.service
do
    printf '%-43s enabled=%-8s active=%s\n' \
        "${unit}" \
        "$(systemctl --user is-enabled "${unit}" 2>/dev/null || true)" \
        "$(systemctl --user is-active "${unit}" 2>/dev/null || true)"
done
printf 'sessionRestore=%s\n' "$(
    kreadconfig5 \
        --file ksmserverrc \
        --group General \
        --key loginMode 2>/dev/null ||
        true
)"

echo
echo "=== VNC ==="
if ss -ltnp | grep -q ':5900'; then
    ss -ltnp | grep ':5900'
    echo "VNC_READY: connect to $(hostname -I | awk '{print $1}'):5900"
else
    echo "VNC_NOT_LISTENING"
fi

echo
echo "=== BU BOOTTAKI KRITIK HATALAR ==="
printf 'EGL_BAD=%s\n' "$(
    journalctl --user -b --no-pager |
        grep -cE 'EGLConfig|Could not create EGL surface|EGL_BAD' ||
        true
)"
printf 'CRASH=%s\n' "$(
    journalctl --user -b --no-pager |
        grep -ciE 'core-dump|segmentation|failed with result' ||
        true
)"
