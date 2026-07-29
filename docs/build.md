# Derleme

## Geliştirici bilgisayarı

Docker dışında host sisteme paket kurulması gerekmez:

```bash
task docker:build
task build
task verify
```

Docker, `linux/arm64` Ubuntu 24.04 ortamında çalışır. x86-64 bilgisayarda
Docker Desktop/QEMU emülasyonu kullanılır; native ARM64 runner daha hızlıdır.

## Kaynak paketleri

KPipeWire ve KRFB için süreç:

1. `source.lock` içindeki Ubuntu Noble kaynak sürümü indirilir.
2. `apt-get build-dep` ile kaynak bağımlılıkları kurulur.
3. Numaralı yamalar sırayla `patch -p1` ile uygulanır.
4. Debian changelog’a T3 yerel sürümü eklenir.
5. `dpkg-buildpackage -b -uc -us` ile ARM64 binary paket üretilir.

T3 yapılandırma ve tema paketleri kendi `Taskfile.yml` dosyalarıyla
`dpkg-deb` üzerinden oluşturulur.

## Mesa kaynağı

Mesa/PowerVR ağacı geçmişte StaticRocket `powervr/24.0.1` tabanı ile Mesa
24.0.5’in birleştirilmesi ve çatışmaların çözülmesiyle üretildi. Nihai
doğrulanmış kısa ağaç kimliği `31d7c27a80` idi.

Yalnızca hazır `.deb` içinden bu kaynak güvenilir biçimde geri üretilemez.
Bu nedenle organizasyon deposuna doğrulanmış tam ağaç bir kez push edilmeli,
sonra immutable tam commit SHA kullanılmalıdır:

```bash
export T3_MESA_SOURCE_URL=https://github.com/t3gemstone/mesa-pvr.git
export T3_MESA_SOURCE_REF=<full-31d7c27a80...-commit>
task build:mesa
```

`scripts/build-mesa.sh`, commit öneki uyuşmazsa paket üretmez.

