# Nöbetçim (iOS)

Yerel hizmet ve işletme bilgilerine odaklanan iOS uygulaması; şu an nöbetçi eczane aramasını sunar, kapsam zamanla genişleyebilir. Web: [nobetcim.info](https://nobetcim.info/)

## Gereksinimler

- macOS + **Xcode 16+**
- iOS **17.0+** hedef
- Apple Developer hesabı (cihaz / TestFlight için)
- [NobetEcza API](https://api.nobetecza.com) anahtarı

## Hızlı başlangıç

```bash
git clone <repo-url>
cd nobetcimMobile
./scripts/setup-secrets.sh
```

`Config/Secrets.xcconfig` dosyasını açıp gerçek API anahtarını yazın:

```xcconfig
NOBETECZA_API_KEY = necz_xxxxxxxx
```

Xcode’da `nobetcim.xcodeproj` → scheme **nobetcim** → gerçek cihaz veya simülatör → Run.

### Simülatörde konum

Varsayılan konum (Cupertino) Türkiye dışıdır; yakındaki eczane listesi boş gelebilir.

**Features → Location → Custom Location** ile örneğin İstanbul koordinatları verin.

### Simülatör konsolu

Xcode konsolunda sık görülen **CoreTelephony XPC**, **nw_connection**, **WebKit**, **CoreMotion**, **audio/HAL** satırları çoğunlukla simülatör kısıtıdır; gerçek cihazda kaybolur veya belirgin azalır. Bunlar **uygulama derleme hatası değildir** ve projede “tamamen kapatılacak” bir anahtar yoktur; Apple/Google sistem süreçlerinin logudur. Gürültüyü azaltmak için (kendi loglarını da kısarak) scheme **Run** → **Arguments** → **Environment** içine `OS_ACTIVITY_MODE` = `disable` eklenebilir.

**Google UMP** akışı bu projede simülatörde bilerek çalıştırılmaz; rıza formunu **gerçek cihazda** ve AdMob’da formlar tanımlıyken doğrulayın. Üretim için **SKAdNetwork** listesi `Config/NobetcimApp-Info.plist` içindedir (Google’ın güncel öneri seti); ileride [3. taraf ağ listesi](https://developers.google.com/admob/ios/3p-skadnetworks) güncellenirse plist’i senkron tutun.

## Proje yapısı

| Klasör | Açıklama |
|--------|----------|
| `nobetcim/` | Ana uygulama (SwiftUI) |
| `NobetcimWidget/` | Ana ekran widget’ı (nöbetçi eczane özeti) |
| `Config/` | Info.plist, `Base.xcconfig`, secret şablonları |
| `scripts/` | Yerel kurulum ve Release doğrulama |
| `ci_scripts/` | Xcode Cloud ön-build script |

## Gizli anahtarlar

| Dosya | Repoda? | Açıklama |
|-------|---------|----------|
| `Config/Secrets.xcconfig` | Hayır | API anahtarı (gitignore) |
| `Config/Secrets.xcconfig.example` | Evet | Şablon |
| `nobetcim/NobetcimConfig.plist` | Hayır | Opsiyonel yerel yedek |
| `nobetcim/NobetcimConfig.example.plist` | Evet | Şablon |

Release build, anahtar yoksa **Validate API Key** script ile durur.

## Google AdMob

Reklam kimlikleri **`nobetcim` target → Build Settings** içinde `ADMOB_APP_ID`, `ADMOB_BANNER_ID`, `ADMOB_INTERSTITIAL_ID` olarak tutulur (`project.pbxproj`). Banner ve geçiş birimleri üretim AdMob kimlikleriyle tanımlıdır.

Geliştirme sırasında [test reklamları](https://developers.google.com/admob/ios/test-ads) kullanmak için cihazı test cihazı olarak kaydedebilir veya geçici olarak test birim kimliklerine dönebilirsiniz.

Yeni birimlerin canlı reklam göstermesi kısa süre gecikebilir; paneldeki **İnceleme gerekli** ve **Gizlilik ve mesajlaşma** adımlarını tamamlayın.

## App Group & imzalama

- Bundle ID: `emrebaglayici.nobetcim` (`Config/Base.xcconfig`)
- Widget: `emrebaglayici.nobetcim.widget`
- App Group: `group.emrebaglayici.nobetcim`
- Team ID: `8XZ69YB7U5` (Apple Developer → Membership)

Apple Developer → **Identifiers** içinde şunları oluştur / güncelle:

1. App ID: `emrebaglayici.nobetcim` (+ App Groups capability)
2. App ID: `emrebaglayici.nobetcim.widget` (+ App Groups)
3. App Group: `group.emrebaglayici.nobetcim`
4. Xcode → Signing & Capabilities → Team: **Emre Baglayici** (`8XZ69YB7U5`)

Eski `talhagergin.*` identifier’ları kullanmayın.

### App Store’a yükleme (Organizer — önerilen yol)

Projede **Automatically manage signing** kullanılır; `REGISTER_APP_GROUPS` kapalıdır (Xcode’un dağıtım sırasında App Store profili oluşturma API’sine gitmesini engeller).

1. **Business** → Agreements / vergi / banka tamam (**Paid Applications** Active).
2. **Xcode → Settings → Accounts** → Apple ID → **Download Manual Profiles**; **Manage Certificates** içinde **Apple Distribution** bu Mac’te var mı bakın.
3. Target **nobetcim** ve **NobetcimWidget** → **Signing & Capabilities** → Team **Emre Baglayici**, kırmızı hata olmamalı.
4. Üst menüden **Any iOS Device (arm64)** seçin (simülatör değil). **`Config/Secrets.xcconfig`** dolu olsun.
5. **Product → Clean Build Folder** → **Product → Archive**.
6. Organizer → **Distribute App** → **App Store Connect** → **Upload** → imzalama için **Automatically manage signing** (veya Xcode’un önerdiği varsayılan) → **Upload**.

Upload bitince App Store Connect → uygulama → **sürüm** → **Build** seç → incelemeye gönder.

**Yedek:** Organizer hâlâ imza hatası verirse `build/export/nobetcim.ipa` + **Transporter** veya `./scripts/upload-app-store.sh` kullanılabilir (`Config/ExportOptions.plist` ile manuel profil adları).

**Çift profil uyarısı:** Apple Developer → Profiles içinde aynı isimden iki **App Store** profili varsa Xcode “profil bulunamadı” verebilir. Eskiyi silin; projede Release imzalama **UUID** ile sabitlenmiştir (`project.pbxproj` içinde `PROVISIONING_PROFILE_SPECIFIER[sdk=iphoneos*]`). Profili yeniden oluşturduysanız UUID’yi Xcode’dan veya `security cms -D -i profil.mobileprovision | plutil -extract UUID raw -` ile güncelleyin.

- **Privacy Policy URL** için `web/gizlilik-politikasi.html` dosyasını nobetcim.info üzerinde yayınlayın (ör. `https://nobetcim.info/gizlilik` veya `/gizlilik-politikasi.html`); App Store Connect Türkçe metadata’da bu tam URL’yi girin. Sayfa 404 olmamalı.

## Xcode Cloud

1. Workflow secret: `NOBETECZA_API_KEY`
2. `ci_scripts/ci_pre_xcodebuild.sh` build öncesi `Config/Secrets.xcconfig` üretir

## Bağımlılıklar (SPM)

- Google Mobile Ads
- Google User Messaging Platform (UMP / rıza)

Çözümleme: Xcode → **File → Packages → Resolve Package Versions**

## Lisans

Özel proje — dağıtım hakları proje sahibine aittir.
