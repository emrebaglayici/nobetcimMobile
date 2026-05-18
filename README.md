# Nöbetçim (iOS)

Türkiye genelinde nöbetçi eczaneleri gösteren iOS uygulaması. Web sitesi: [nobetcim.info](https://nobetcim.info/)

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

## Proje yapısı

| Klasör | Açıklama |
|--------|----------|
| `nobetcim/` | Ana uygulama (SwiftUI) |
| `NobetcimWidget/` | Yakındaki eczane widget’ı |
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

## Xcode Cloud

1. Workflow secret: `NOBETECZA_API_KEY`
2. `ci_scripts/ci_pre_xcodebuild.sh` build öncesi `Config/Secrets.xcconfig` üretir

## Bağımlılıklar (SPM)

- Google Mobile Ads
- Google User Messaging Platform (UMP / rıza)

Çözümleme: Xcode → **File → Packages → Resolve Package Versions**

## Lisans

Özel proje — dağıtım hakları proje sahibine aittir.
