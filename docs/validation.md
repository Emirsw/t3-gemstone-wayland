# Kart doğrulaması

Paketler bir test karta kurulduktan sonra:

```bash
dpkg-query -W \
  t3-mesa-pvr-2405-test krfb libkpipewire5 \
  t3-plasma-wayland-config t3-gemstone-theme t3-plymouth-theme

loginctl show-session "$XDG_SESSION_ID" -p Type -p Desktop
qdbus org.kde.KWin /KWin supportInformation |
  grep -E 'Compositing Type|OpenGL vendor|OpenGL renderer|OpenGL platform'

systemctl --user is-active plasma-kwin_wayland.service
systemctl --user is-active plasma-plasmashell.service
systemctl --user is-active t3-krfb-wayland.service
ss -ltnp | grep ':5900'
```

Beklenen GPU:

```text
OpenGL vendor string: Imagination Technologies
OpenGL renderer string: PowerVR B-Series BXS-4-64
OpenGL platform interface: EGL
```

KPipeWire ve KRFB servis ortamında:

```text
T3_KPIPEWIRE_FORCE_SHM=1
T3_KRFB_Y_INVERT=1
```

Uzun süreli testte KWin/Plasma restart sayısı, RAM, CPU, VNC kareleri ve
kernel GPU fault kayıtları ayrıca izlenmelidir.

