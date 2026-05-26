# CI/CD: GitHub Actions → Firebase App Distribution

**Hedef:** Sen istediğinde (GitHub’da tek tık) APK derlenir, Firebase’e yüklenir, telefona **e-posta bildirimi** gider. Her `git push` otomatik dağıtım **yok**.

**Maliyet:** Kişisel kullanım için genelde **0 TL** (aşağıya bak).

---

## Nasıl çalışır?

```text
GitHub → Actions → "Android Firebase Distribute" → Run workflow
  → flutter build apk (versionCode = run #, otomatik artar)
  → firebase appdistribution:distribute
  → Firebase e-posta: "Yeni build hazır"
  → Telefonda linke tıkla → Kur
```

Kodunu normal `git push` ile atarsın; **telefona build gitmez** ta ki workflow’u çalıştırana kadar.

**Not:** Tamamen arka planda otomatik kurulum yok (Android güvenliği). Ama indir–sil–Dosyalar yok; Firebase tek tıkla kurulum sayfası açar.

---

## Uygulama içi güncelleme (e-posta yerine)

**Hedef ekranı** → **«Güncellemeyi kontrol et»** (Firebase App Distribution SDK).

| Adım | Ne olur |
|------|---------|
| 1 (bir kez) | `android/app/google-services.json` — Firebase Console → Android app → indir |
| 2 (bir kez) | Google Cloud → **Firebase App Testers API** etkin |
| 3 (bir kez) | Uygulamada butona bas → tester Google hesabıyla giriş |
| 4 | GitHub’da **Run workflow** ile yeni APK dağıt |
| 5 | Uygulamada **Güncellemeyi kontrol et** → indir → **Kur** |

E-posta bildirimi isteğe bağlı; güncellemeyi uygulama içinden yönetebilirsin.

**CI için:** `google-services.json` dosyasını GitHub secret `GOOGLE_SERVICES_JSON` (ham JSON) olarak ekle; workflow build öncesi `android/app/` altına yazar (secret listesine eklenebilir).

**Debug `flutter run`:** Buton «yalnızca release build» der; telefonda CI’dan gelen **release APK** kullan.

---

## 1) Firebase projesi (bir kez)

1. [Firebase Console](https://console.firebase.google.com/) → proje oluştur (veya mevcut).
2. **Android uygulaması ekle**
   - Paket adı: `com.alper.music_theory_trainer` (projeyle aynı olmalı).
3. `google-services.json` **zorunlu değil** (sadece dağıtım için CLI yeterli).
4. Sol menü → **App Distribution** → **Get started**.
5. **Testers** sekmesi → grubu oluştur, örn. `testers`.
6. Kendi Gmail’ini gruba veya doğrudan tester olarak ekle.
7. İlk davet e-postasındaki adımları tamamla (tester onboarding).

**Android App ID** (dağıtım için gerekli):

- Firebase Console → Proje ayarları → Genel → Uygulamalar → Android
- veya App Distribution → uygulama seç → URL’de `1:XXXX:android:YYYY` formatı

Bu değeri kopyala → GitHub secret `FIREBASE_ANDROID_APP_ID`.

---

## 2) Service account (CI kimliği, bir kez)

1. [Google Cloud Console](https://console.cloud.google.com/) → aynı Firebase projesi.
2. **IAM & Admin** → **Service Accounts** → **Create**.
3. Rol: **Firebase App Distribution Admin** (veya Editor test için).
4. **Keys** → Add key → JSON → indir.
5. JSON dosyasının **tüm içeriğini** GitHub secret olarak yapıştır (tek satır olabilir).

---

## 3) Release keystore (önerilir, bir kez)

Aynı imza = telefonda veri korunur, üstüne güncelleme.

```powershell
cd android\app
keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

`android/key.properties` oluştur (`key.properties.example` kopyala).

CI için keystore’u Base64:

```powershell
[Convert]::ToBase64String([IO.File]::ReadAllBytes("android\app\upload-keystore.jks")) | Set-Clipboard
```

**Keystore secret’ları olmadan** workflow yine çalışır (debug imza). İlk test için yeterli; uzun vadede release keystore secret’larını ekle.

---

## 4) GitHub repository secrets

Repo → **Settings** → **Secrets and variables** → **Actions** → **New repository secret**

| Secret | Zorunlu | Açıklama |
|--------|---------|----------|
| `FIREBASE_SERVICE_ACCOUNT_JSON` | Evet | Service account JSON dosyasının tam metni |
| `FIREBASE_ANDROID_APP_ID` | Evet | `1:123456789:android:abcdef...` |
| `FIREBASE_TESTER_GROUPS` | Biri | Örn. `testers` (virgülle birden fazla grup) |
| `FIREBASE_TESTER_EMAILS` | Biri | Örn. `sen@gmail.com,arkadas@gmail.com` |
| `ANDROID_KEYSTORE_BASE64` | Hayır | Keystore dosyası Base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Hayır* | *Keystore kullanıyorsan evet |
| `ANDROID_KEY_PASSWORD` | Hayır* | |
| `ANDROID_KEY_ALIAS` | Hayır* | Örn. `upload` |

\* `ANDROID_KEYSTORE_BASE64` doluysa diğer üç keystore secret’ı da gerekli.

---

## Ücret (1. sorunun cevabı)

| Hizmet | Ücret |
|--------|--------|
| **GitHub remote (git push)** | Ücretsiz (public/private repo) |
| **GitHub Actions** | Özel repoda ayda ~**2000 dakika ücretsiz**; bu workflow build başına ~10–15 dk → ayda onlarca manuel dağıtım sığar |
| **Firebase App Distribution** | **Spark plan = ücretsiz** (tester dağıtımı) |
| **Firebase / Google Cloud** | Bu pipeline için ekstra kart gerekmez |

Özet: **Remote’a kod atmak paralı değil.** Sadece Actions kotanı çok sık tetiklersen (günde onlarca build) limit konuşulur; **haftada birkaç manuel dağıtım** rahatlıkla ücretsiz.

---

## 5) İlk deploy ve sonraki güncellemeler

```bash
git push origin main   # sadece kodu remote'a atar, APK dagitimi YOK
```

Telefona build göndermek için:

1. GitHub repo → **Actions**
2. **Android Firebase Distribute** → **Run workflow**
3. İsteğe bağlı release notu yaz → **Run workflow**
4. Yeşil bitince telefona Firebase maili gelir

Başarılı olunca:

- Telefona Firebase e-postası gelir.
- Linke tıkla → APK kurulur.
- Sonraki push’larda yine e-posta gelir; **Kur** ile güncellersin (veri aynı imzada kalır).

---

## Sürümleme

| Alan | Kaynak |
|------|--------|
| `versionName` | `pubspec.yaml` (`1.0.1` kısmı) |
| `versionCode` | GitHub `run_number` (her workflow’da +1) |

`pubspec.yaml` içindeki `+2` build numarası yerel içindir; CI `run_number` kullanır.

---

## Ne zaman dağıtım yapılır?

**Her `git push` APK üretmez.** Üç yol:

| Yöntem | Ne yaparsın |
|--------|-------------|
| **Sadece kod** | Normal `git push` veya `.\scripts\git-push.ps1` |
| **Push + APK (kolay)** | `.\scripts\git-push.ps1 -Deploy` (GitHub UI yok, `gh` gerekir) |
| **Commit etiketi** | `git commit -m "fix: ... [apk]"` sonra normal `git push` |
| **Yedek** | Actions → Run workflow |

Tüm projelerde workspace script: `c:\cursorProjects\scripts\git-push-firebase.ps1 -Project music|weekly|yuruk [-Deploy]`

---

## Sorun giderme

| Sorun | Çözüm |
|-------|--------|
| Secret eksik | Actions log’da hangi secret yazıyor; tabloyu doldur |
| App ID yanlış | Paket adı Firebase’deki ile aynı mı kontrol et |
| E-posta gelmiyor | Tester daveti kabul edildi mi; spam klasörü |
| Kurulumda «uygulama yüklenemedi» | İmza değişti (debug↔release); eski uygulamayı kaldırıp tekrar kur |
| Workflow Gradle hatası | Actions log; Flutter/Java 17 kullanılıyor |

---

## Yerel geliştirme

CI kurulduktan sonra yerelde hâlâ:

```bash
flutter run
```

İstersen nadiren USB: `adb install -r build/.../app-release.apk` — **zorunlu değil**.

---

## Ücretsiz limitler (özet)

- **GitHub Actions:** Özel repo ~2000 dk/ay (Flutter build ~10–15 dk → yüzlerce build/ay).
- **Firebase App Distribution:** Spark planında tester dağıtımı ücretsiz (makul kullanım).

Play Store yayını bu pipeline’ın parçası değildir.
