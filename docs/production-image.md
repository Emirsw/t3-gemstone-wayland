# Üretim imajı modeli

Üretim imajı, çalışan bir SD kartın veya geliştirici makinesinin kopyası değildir.
Her çalıştırmada doğrulanmış resmi minimal Gemstone imajından başlanır ve T3
paketleri kaynak koddan yeniden oluşturularak temiz bir kök dosya sistemine
kurulur.

## Güven zinciri

1. `image/source.lock`, resmi minimal imajın URL, boyut ve SHA-256 değerlerini sabitler.
2. KPipeWire ve KRFB, Ubuntu kaynak paketleri ile depodaki incelenebilir yamalardan oluşturulur.
3. Mesa PowerVR, kuruluş tarafından onaylanan depodaki tam 40 karakterlik commit üzerinden oluşturulur. Üretim iş akışı hazır Mesa `.deb` dosyasına geri düşmez.
4. Tema, Plymouth ve Plasma yapılandırması bu depodaki tariflerden oluşturulur.
5. Paketler resmi minimal imajın chroot ortamına kurulur.
6. Makine kimliği, SSH host anahtarları, ağ profilleri, kullanıcı anahtarları, geçmiş, cache ve loglar temizlenir.
7. Boot bölümü `image/boot-files.allow` ile doğrulanır. Fazladan veya eksik bir üst seviye dosya imaj üretimini durdurur.
8. Sıkıştırılmış imaj; SHA-256, paket manifesti ve JSON build provenance dosyası ile birlikte yayımlanır.

## GitHub değişkenleri

Repository **Settings → Secrets and variables → Actions → Variables** alanına:

| Değişken | Değer |
|---|---|
| `T3_MESA_SOURCE_URL` | Onaylı, birleştirilmiş Mesa PowerVR kaynak deposunun HTTPS adresi |
| `T3_MESA_SOURCE_REF` | `31d7c27a80` ile başlayan, tam 40 karakterlik değişmez commit SHA |

Dal adı veya etiket kabul edilmez. Böylece aynı Action daha sonra başka bir
kaynak ağacına sessizce yönlendirilemez.

## Action çıktıları

- `t3-gemstone-wayland-<sürüm>-arm64.img.xz`
- `.img.xz.sha256`
- Kurulan T3 paketlerini içeren `.manifest.txt`
- Kaynak commit, taban imaj hash'i ve temizleme politikasını içeren `.buildinfo.json`

## Yerel üretim

```bash
export T3_MESA_SOURCE_URL=https://github.com/KURULUS/mesa-pvr.git
export T3_MESA_SOURCE_REF=<tam-40-karakterlik-commit>
export IMAGE_VERSION=1.0.0

task build:image
sha256sum --check dist/*.img.xz.sha256
```

## Donanım kabul kapısı

CI çıktısı üretim sürümü sayılmadan önce gerçek T3 Gemstone O1 kartında soğuk
açılış, HDMI 720p, Wayland/PowerVR, USB, Wi-Fi, Bluetooth, KRFB/VNC ve en az iki
saat masaüstü kararlılık testlerinden geçmelidir. Sonuç sürüm notuna eklenmeden
imaj `production` etiketiyle yayımlanmamalıdır.
