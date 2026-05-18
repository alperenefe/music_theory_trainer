# Müzik Teorisi (`music_theory_trainer`)

Sol anahtar üzerinde **doğal notalarla** portre pratiği, **gitar fretboard** (standart akort, 0–7. perde) ile üç pratik modu, **mikrofonla gerçek gitar** egzersizi ve **kalıcı hedef + istatistik** sunan Flutter uygulaması. Arayüz metinleri Türkçe; tema koyu (lacivert / mor tonları).

---

## Özellikler

| Alan | Açıklama |
|------|----------|
| **Portede yerleştir** | Hedef notanın portede doğru çizgi/aralığa denk geldiği yeri seçip onaylama. |
| **Notayı tanı** | Portede gösterilen doğal notanın adını çoktan seçmeli olarak işaretleme. |
| **Hedef ve aralık** | Egzersiz türüne göre hedef deneme sayısı; portre egzersizleri için **MIDI nota aralığı** (varsayılan gitar 0–7 ile uyumlu **40–71**). Ses açık/kapalı. |
| **Gitarda nota ne?** | Vurgulanan perde için nota adı (MCQ). |
| **Gitarda notayı bul** | Verilen notayı fretboard üzerinde dokunarak bulma; aynı pitch’te birden fazla perde doğru sayılır. |
| **Gitarda notayı çal** | Hedef notayı kendi gitarından çalma; mikrofon frekanstan nota adı çıkarır (arka plan sessizliği ve tek nota önerilir). |
| **İstatistikler** | Son denemeler, doğruluk, ortalama süre, notaya göre özet; mini eğri (sparkline). |
| **Hedef tamamlandı** | Hedef dolunca özet diyalog (doğruluk, seri, medyan süre vb.). |
| **Onboarding** | İlk açılışta kısa 3 adımlı tanıtım (bir kez tamamlanınca tekrar gösterilmez). |

**UX / geri bildirim:** Sayfa geçişlerinde fade + hafif slide; doğru/yanlışta alt geri bildirim çubuğu, titreşim ve kısa UI tonu (ses açıksa). **Notayı tanı** ekranında üstte yalnızca **hedef** özeti; porte ile şıklar kaydırılabilir. Metin ölçeği sistem değerine göre **0.88–1.28** aralığında sınırlanır.

**Ses:** Gitar önizlemesi için sentez tabanlı servis (`audioplayers` ile kısa WAV). Ana ekrandan ses kısayolu.

**İkon:** `assets/branding/app_icon.png` — Android uyarlanabilir ikon ve iOS `AppIcon` için `flutter_launcher_icons` yapılandırması `pubspec.yaml` içinde.

---

## Gereksinimler

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (projede `environment.sdk: ^3.10.8`)
- Android Studio / Xcode hedef platforma göre; fiziksel cihaz için USB hata ayıklama ve `adb`

---

## Kurulum ve çalıştırma

```bash
cd music_theory_trainer
flutter pub get
flutter run
```

Belirli cihaz:

```bash
flutter devices
flutter run -d <cihaz_id>
```

---

## Kalite: analiz ve test

```bash
flutter analyze
flutter test
```

`integration_test` ve bazı widget testleri, geliştirme ortamında **Material ink sparkle** shader sürümüyle çakışırsa hata verebilir; birim testleri (`test/models`, `test/services` vb.) bu durumdan bağımsız çalışır.

---

## Release APK

```bash
flutter build apk --release
```

Çıktı dosyası:

`build/app/outputs/flutter-apk/app-release.apk`

USB ile kurulum:

```bash
adb install -r build/app/outputs/flutter-apk/app-release.apk
```

veya:

```bash
flutter install -d <cihaz_id>
```

---

## Launcher ikonunu yeniden üretme

Kaynak görsel: `assets/branding/app_icon.png`. Ardından:

```bash
dart run flutter_launcher_icons
```

---

## Veri ve tercihler

Tümü **SharedPreferences** üzerinde JSON string olarak saklanır.

| Anahtar | İçerik |
|---------|--------|
| `practice_prefs_v1` | `PracticePrefs`: `poolMinMidi`, `poolMaxMidi`, `goalKind`, `goalTarget`, `goalProgress`, `goalStartedAtMillis`, `soundEnabled`, `onboardingDone` |
| `practice_attempts_v1` | `PracticeAttempt` listesi: egzersiz kimliği, MIDI, doğru/yanlış, gecikme (ms), zaman damgası |

**Varsayılan portre havuzu (yeni kurulum):** MIDI **40** (kalın Mi boş) – **71** (ince tel 7. perde Si), doğal notalar ve genişletilmiş porte slotları `NotationPitch` içinde tanımlı.

**Hedef türleri (`goalKind`):** `placement`, `mcq`, `gitar_mcq`, `gitar_bul`, `gitar_cal` veya `null` (hedef yok). İlerleme, eşleşen egzersizde her doğru/yanlış denemeden sonra güncellenir; hedef dolunca sıfırlanıp tamamlanma ekranı gösterilir.

---

## Egzersiz kimlikleri (kod / kayıt)

İstatistik ve hedef eşlemesinde kullanılan sabitler (`AppStrings`):

- Portede yerleştir → `yerlestir`
- Notayı tanı → `coktan_secmeli`
- Gitarda nota ne? → `gitar_mcq`
- Gitarda notayı bul → `gitar_bul`
- Gitarda notayı çal → `gitar_cal`

---

## Mimari özeti (`lib/`)

- **`screens/`** — Ana akış ekranları; `goals/` altında hedef parçaları.
- **`models/`** — `NotationPitch`, `GuitarNote`, `PracticeAttempt`, `PracticePrefs`.
- **`services/`** — Tercih ve istatistik depoları, hedef takibi, gitar sesi, UI tonu, sparkline serisi.
- **`staff/`** — Sol anahtar çizimi, porte geometrisi, etkileşimli alan widget’ı.
- **`guitar/`** — Fretboard painter ve widget.
- **`widgets/`** — Kartlar, geri bildirim çubuğu, onboarding, istatistik sparkline vb.
- **`utils/`** — Frekans → MIDI yardımcıları (`PitchFromHz`).
- **`l10n/app_strings.dart`** — Türkçe sabit metinler.

---

## Bağımlılıklar (özet)

| Paket | Rol |
|-------|-----|
| `shared_preferences` | Tercihler ve deneme geçmişi |
| `google_fonts` | Tipografi |
| `flutter_animate` | Giriş animasyonları |
| `audioplayers` | Gitar önizleme sesi |
| `flutter_detect_pitch` | Mikrofon frekansı (gitarda çal) |
| `permission_handler` | Mikrofon izni |
| `flutter_launcher_icons` (dev) | Uygulama ikonları |

Tam liste: `pubspec.yaml`.

---

## Lisans ve katkı

Proje `publish_to: 'none'` ile özel kullanım için yapılandırılmıştır. Lisans dosyası eklenmediyse depoya bir `LICENSE` eklemen önerilir.
