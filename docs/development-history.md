# T3 Gemstone Wayland geliştirme özeti

Bu belge T3 Gemstone O1 (TI AM67A, ARM64) üzerinde yürütülen Wayland geçişinin
yeniden üretilebilir teknik kapsamını özetler.

## Grafik zinciri

- PowerVR B-Series BXS-4-64 GPU, `pvrsrvkm` ve TI IMG kullanıcı alanı
  kütüphaneleriyle doğrulandı.
- Mesa PowerVR Gallium sürücüsü sistem Mesa'sını değiştirmeden `/opt` altında
  izole paket olarak hazırlandı.
- Mesa 24.0.1 ile Ubuntu 24.04 Mesa 24.0.5 arasındaki ABI uyumsuzluğu incelendi;
  test paketi 24.0.5 tabanına taşındı.
- Weston GL renderer günlüklerinde `Imagination Technologies` ve
  `PowerVR B-Series BXS-4-64` çıktıları doğrulandı.

## KDE Plasma Wayland

- SDDM üzerinde özel `T3 Plasma (Wayland + PowerVR)` oturumu tanımlandı.
- KWin, PowerVR EGL/GBM/DRI kütüphaneleriyle çalışacak şekilde izole ortamdan
  başlatıldı.
- Plasma'nın kararlılığı için doğrudan scanout, renk derinliği ve gereksiz
  kullanıcı servisleri üzerinde uyumluluk ayarları uygulandı.
- T3 renk şeması, Plasma görünümü, başlatıcı ikonu, sistem durumu plasmoidi ve
  duvar kâğıtları Debian paketi haline getirildi.
- Plymouth açılış teması ayrı ve geri alınabilir bir paket olarak hazırlandı.

## Wayland uzaktan masaüstü

- Weston VNC ve KDE KRFB/PipeWire yolları ayrı ayrı test edildi.
- PowerVR ekran yakalamada görülen ters görüntü ve satır kopyalama sorunları
  KRFB yamalarıyla ele alındı.
- KPipeWire için isteğe bağlı SHM yakalama yolu eklendi.
- Sabit/shared VNC parolası dağıtılmaz; unattended access kullanıcı tarafından
  yerel olarak etkinleştirilmelidir.

## Chromium ve video hızlandırma

- Hazır Chromium paketinin `/dev/video0` Wave5 decoder yolunu açmadığı ölçüldü.
- TI meta-arago Chromium V4L2 yamaları güncel Chromium kaynağına taşındı.
- ARM64, Ozone Wayland, proprietary H.264 ve V4L2 codec özellikleriyle özel
  Chromium build tarifi oluşturuldu.
- Kartta kararlı aygıt isimleri için `/dev/video-dec0` ve `/dev/video-enc0`
  udev kuralları eklendi.
- Başarı ölçütü, `chrome://media-internals` içinde V4L2 decoder ve Chromium
  sürecinde Wave5 aygıtının açık görünmesidir.

## Paketleme ve yeniden üretilebilirlik

- Hazır binary dosyalar yerine kaynak kilitleri, açık yamalar, Debian paket
  iskeletleri, Docker build ortamı ve Taskfile kullanılır.
- CI shell sözdizimini, patch sayısını ve secret politikasını doğrular.
- İsteğe bağlı ARM64 workflow paketleri üretir; release workflow sürüm
  etiketlerinde `.deb`, SHA-256 ve SPDX SBOM yayımlar.
- Derleme çıktıları, upstream checkout'lar, cihaz parolaları ve özel ağ
  bilgileri sürüm kontrolüne alınmaz.
