# T3 Gemstone AM67A Chromium V4L2/Wave5

Bu yapılandırma Chromium 152 kaynak ağacına AM67A'nın stateful Wave5 VPU
yolunu ekler. Hedef, H.264 videonun CPU yerine `/dev/video0` üzerinden
çözülmesidir.

## Derleme

Kaynak kodun bulunduğu Linux/Docker makinesinde:

```bash
cd /work/chromium/src
git status --short

cd /path/to/chromium-v4l2-wave5
chmod +x apply-ti-patches.sh build.sh package.sh \
  run-chromium-wave5.sh verify-on-card.sh

CHROMIUM_SRC=/work/chromium/src \
JOBS=32 \
./build.sh

CHROMIUM_SRC=/work/chromium/src \
./package.sh
```

Önemli GN değerleri:

```text
use_v4l2_codec=true
use_vaapi=false
proprietary_codecs=true
ffmpeg_branding="Chrome"
```

`build.sh`, TI meta-arago deposundaki dört AM67/Wave5 Chromium yamasını önce
uygular:

1. Chromium'un `/dev/video-dec0` adlandırmasını kullanması
2. GPU/video sandbox'ının V4L2 aygıtına erişmesi
3. Wave5 OUTPUT/CAPTURE queue başlatma düzeltmesi
4. Eksik H.264 access unit'lerinin sürücüye gönderilmemesi

Kartta aygıt adlarını kalıcı oluşturmak için:

```bash
sudo install -m 0644 67-t3-wave5.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger --subsystem-match=video4linux
ls -l /dev/video-dec0 /dev/video-enc0
```

## Kartta doğrulama

Paketi karta kurup Chromium'u `run-chromium-wave5.sh` ile başlatın. YouTube'da
Stats for nerds bölümünde codec `avc1` olmalıdır. Video oynarken:

```bash
./verify-on-card.sh
```

Başarı ölçütleri:

- Chromium süreçlerinden biri `/dev/video0` açar.
- `chrome://media-internals` içindeki `video_decoder`, `GpuVideoDecoder` olur.
- Codec `avc1` olur; VP9/AV1 Wave5 tarafından çözülmez.
- 1080p30 veya 720p30 videoda CPU kullanımı yazılım çözmeye göre belirgin düşer.

Bu paket yalnızca AM67A hedefi olduğu için `use_vaapi=false` seçilmiştir;
çalışma zamanında backend seçmeye gerek kalmadan V4L2 kullanılır.
