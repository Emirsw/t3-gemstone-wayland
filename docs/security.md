# Güvenlik ve tedarik zinciri

- Kaynak referansları immutable commit veya tam Debian sürümüdür.
- CI yalnızca repodaki yamaları uygular; ağdan hazır T3 binary indirmez.
- GitHub Actions izinleri en az yetkiyle tanımlanmıştır.
- PR iş akışı release yazma yetkisi taşımaz.
- Tag release’i SHA-256 ve SPDX manifestleriyle yayımlanır.
- GPG/SSH özel anahtarları, Wi-Fi/VNC/kart parolaları ve sertifikalar
  kesinlikle repoya eklenmez.
- Gerçek üretim için GitHub Environment onayı, korumalı tag ve imzalı
  release kullanılması önerilir.

Mesa kaynağı doğrulama kuralı bilerek fail-closed tasarlanmıştır. Kurum
deposuna tam doğrulanmış commit aktarılmadan Mesa release’i üretilmemelidir.

