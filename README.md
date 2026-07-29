# T3 Gemstone Wayland Packages

T3 Gemstone O1 (TI AM67A, ARM64) için PowerVR hızlandırmalı KDE Plasma
Wayland yazılım zincirinin yeniden üretilebilir paketleme deposudur.

Bu depo hazır `.deb` dosyalarını güven kaynağı olarak kabul etmez. Paketler;
sabitlenmiş upstream kaynakları, incelenebilir T3 yamaları, Debian paket
tarifleri ve CI üzerinden yeniden üretilir.

## Üretilen paketler

| Paket | Amaç |
|---|---|
| `t3-mesa-pvr-2405-test` | İzole Mesa/PowerVR çalışma zamanı |
| `libkpipewire* ... +t3pvr1` | PowerVR için isteğe bağlı SHM ekran yakalama |
| `krfb ... +t3pvr3` | Dikey düzeltme, doğrudan kopyalama ve damage tracking |
| `t3-plasma-wayland-config` | SDDM, Plasma Wayland, PowerVR ve VNC yapılandırması |
| `t3-gemstone-theme` | T3 masaüstü teması |
| `t3-plymouth-theme` | T3 açılış ekranı |

## Hızlı başlangıç

Gerekenler: Docker Desktop/Engine, Docker Compose ve
[Task](https://taskfile.dev/).

```bash
task doctor
task docker:build
task build
task verify
```

Çıktılar `dist/` altına yazılır. Tek paket için:

```bash
task build:krfb
task build:kpipewire
task build:config
task build:theme
task build:plymouth
```

Mesa paketi için doğrulanmış birleşik kaynak gereklidir. Kurum içi Git
deposunda `T3_MESA_SOURCE_URL` ve `T3_MESA_SOURCE_REF` tanımlanmalıdır.
Geçmişte doğrulanan ağacın kısa kimliği `31d7c27a80`, PowerVR tabanı ise
`7c82c1eebc67f5a62a347a84d42fe795cf7f523b` idi. Eksik veya farklı kaynakta
betik güvenli biçimde durur; binary’den “kaynak üretmez”.

```bash
T3_MESA_SOURCE_URL=https://github.com/ORGANIZATION/mesa-pvr.git \
T3_MESA_SOURCE_REF=31d7c27a80 \
task build:mesa
```

## Güvenlik modeli

- Upstream sürümler `source.lock` dosyalarında sabittir.
- Yamalar repoda açıkça incelenebilir.
- CI, yamaların temiz uygulanmasını ve shell sözdizimini doğrular.
- Her `.deb` için SHA-256 ve SPDX JSON SBOM/manifest üretilir.
- Release artefaktları GitHub Actions tarafından üretilebilir.
- Özel anahtar, kart parolası ve ağ kimlik bilgisi repoya konmaz.

Detaylar için [build.md](docs/build.md), [security.md](docs/security.md) ve
[validation.md](docs/validation.md) belgelerine bakın.

## Chromium Wave5 / V4L2

`packages/chromium-v4l2-wave5/`, T3 Gemstone AM67A üzerindeki Wave5 VPU için
Chromium ARM64 derleme tarifini ve TI V4L2 yamalarını içerir. Chromium kaynak
ağacı ve derlenmiş tarayıcı bu depoya eklenmez; sabitlenmiş upstream kaynak
üzerine yamalar uygulanarak yerel derleme yapılır.

```bash
task chromium:check
cd packages/chromium-v4l2-wave5
./apply-ti-patches.sh /path/to/chromium/src
./build.sh /path/to/chromium/src
```

Kart üzerindeki hedef doğrulama, Chromium sürecinin Wave5 video aygıtını açması
ve `chrome://media-internals` içinde V4L2 donanımsal decoder yolunun görünmesidir.

## Tema varlıkları

`assets/` altında T3 Gemstone 10. yıl başlatıcı ikonları ve 1920x1080 masaüstü
duvar kâğıtları bulunur. Dağıtılan temel Plasma teması
`packages/theme/package/` altındadır.

## Depo yapısı

```text
.github/workflows/              CI ve release iş akışları
assets/                         sürümlenen ikon ve wallpaper varlıkları
docker/                         ARM64 paket derleme ortamı
docs/                           build, güvenlik ve doğrulama belgeleri
packages/
  chromium-v4l2-wave5/          Wave5/V4L2 Chromium tarifleri ve yamaları
  kpipewire/                    PowerVR ekran yakalama yaması
  krfb/                         VNC görüntü/damage tracking yamaları
  mesa-pvr/                     sabitlenmiş Mesa kaynak tanımı
  plasma-wayland-config/        SDDM/KWin/PowerVR yapılandırma paketi
  plymouth-theme/               açılış ekranı paketi
  theme/                        Plasma tema paketi
scripts/                        build, kontrol, SBOM ve doğrulama araçları
Taskfile.yml                    tek komutlu build giriş noktası
```

Projenin bugüne kadarki teknik özeti için
[development-history.md](docs/development-history.md) belgesine bakın.
