abstract final class AppStrings {
  static const appTitle = 'Müzik Teorisi';
  static const homeSubtitle = 'Sol anahtar, doğal notalarla pratik.';
  static const homeSectionStaff = 'Porte & okuma';
  static const homeSectionTheory = 'Müzik teorisi';
  static const homeSectionGuitar = 'Gitar';
  static const homeSectionTools = 'Ayarlar';
  static const homeStreakNone = 'Bugün pratik yok — bir deneme ile seriyi başlat';
  static String homeStreakDays(int n) => '$n günlük pratik serisi';
  static const homeGlobalAccuracy = 'Genel doğruluk';
  static const homeMicBadge = 'Mikrofon';
  static const homeCtaTuner = 'Akort';
  static const homeCtaGoals = 'Hedefler';
  static const homePrivacyFooter =
      'Tüm veriler yalnızca cihazında saklanır; buluta gönderilmez.';
  static const tunerPrivacyNote =
      'Mikrofon yalnızca akort için kullanılır; ses kaydı saklanmaz.';
  static String sessionScore(int correct, int total) =>
      'Puan: $correct/$total';
  static const placementTitle = 'Portede yerleştir';
  static const placementDesc =
      'Hedef notayı portede doğru çizgi veya aralığa yerleştirip onayla.';
  static const placementTapHint = 'Dokun veya sürükle';
  static const mcqTitle = 'Notayı tanı';
  static const mcqDesc = 'Portede gösterilen notanın adını seç.';
  static const statsTitle = 'İstatistikler';
  static const statsDesc = 'Deneme, doğruluk ve ortalama süre.';
  static const exerciseStatsTitle = 'İstatistikler';
  static const exerciseStatsEmpty = 'Henüz bu etkinlikte deneme yok.';
  static String exerciseStatsWindow(int n) => 'Son $n deneme';
  static const exerciseStatsGoalPeriod =
      'Bu hedef dönemi — nota istatistikleri sıfırdan';
  static const clearExerciseStats = 'Bu etkinliğin kayıtlarını sil';
  static const clearExerciseStatsTitle = 'Etkinlik kayıtları silinsin mi?';
  static const clearExerciseStatsBody =
      'Yalnızca bu alıştırmaya ait denemeler silinir; diğer etkinlikler kalır.';
  static const start = 'Başla';
  static const confirm = 'Onayla';
  static const next = 'Sonraki';
  static const targetLabel = 'Hedef';
  static const tapStaff =
      'Porteye dokun veya parmağını sürükle: çizgi veya aralık seçilir.';
  static const correct = 'Doğru';
  static const wrong = 'Yanlış';
  static const wrongYourPick = 'Seçimin';
  static const wrongCorrectIs = 'Doğru cevap';
  static const placementOffsetLabel = 'Portede konum';
  static const clearStats = 'İstatistikleri sıfırla';
  static const attempts = 'Deneme';
  static const avgTime = 'Ort. süre';
  static const accuracy = 'Doğruluk';
  static const perMidi = 'Notaya göre';
  static const noData = 'Henüz kayıt yok.';
  static const back = 'Geri';
  static const selectSlotFirst = 'Önce portede bir yer seç.';
  static const exercisePlacement = 'yerlestir';
  static const exerciseMcq = 'coktan_secmeli';
  static const intervalTitle = 'Aralık tanı';
  static const intervalDesc =
      'Kök notadan yukarı veya aşağı aralık (küçük/büyük 2–3, tam 4–5) — oktavsız nota adı.';
  static const exerciseInterval = 'aralik';
  static const scaleTitle = 'Gam kur';
  static const scaleDesc =
      'Tüm notalardan gamı doğru sırayla seç; bitince süre durur, yanlışta yeni gam.';
  static const exerciseScale = 'gam';
  static const scaleStepLabel = 'derece';
  static const scaleTimerLabel = 'Süre';
  static const scalePickedSoFar = 'Seçilenler';
  static const scaleTime = 'Süre';
  static const chordTitle = 'Akor tanı / kur';
  static const chordDesc =
      'Akor adından notaları veya notalardan akor adını bul.';
  static const exerciseChord = 'akor';
  static const questionLabel = 'Soru';
  static const goalProgressAttempts = 'Deneme sayısı';
  static const goalProgressAccuracy = 'Doğruluk';
  static const goalProgressSpeed = 'Hız (ort. süre)';
  static const goalAccuracyTargetSection = 'Doğruluk hedefi';
  static const goalSpeedTargetSection = 'Süre hedefi (ortalama)';
  static const goalSpeedTargetHint =
      'Bu sürenin altında ortalama kalırsan hız hedefi tutar.';
  static const goalSpeedTargetHintShort =
      'Ortalama bu sürenin altında olmalı.';
  static const exercisePrefsGoalLine = 'Hedef';
  static const exercisePrefsGoalOtherExercise =
      'Seçili hedef başka bir alıştırmada.';
  static const goalsTitle = 'Hedef ve aralık';
  static const replayOnboarding = 'Tanıtımı tekrar göster';
  static const goalsDesc =
      'Açık hedefler ana ekranda ilerleme çubuğu gösterir.';
  static const customWorkoutTitle = 'Özel antrenman';
  static const customWorkoutDesc =
      'Egzersiz türü, nota aralığı ve (aralık modunda) çalışılacak aralıkları seç.';
  static const customWorkoutExerciseSection = 'Egzersiz';
  static const customWorkoutIntervalSection = 'Aralık türleri';
  static const customWorkoutStart = 'Antrenmana başla';
  static const customWorkoutSave = 'Ayarları kaydet';
  static const goalPerActivitySection = 'Etkinlik hedefleri';
  static const goalCompletedHistorySection = 'Tamamlanan hedefler';
  static const goalCompletedHistoryEmpty =
      'Henüz tamamlanan hedef yok. Bir hedefi bitirdiğinde burada görünür.';
  static String goalCompletedHistoryLine({
    required String date,
    required int target,
    required int accuracyPercent,
  }) =>
      '$date · $target deneme · %$accuracyPercent';
  static const goalKindSection = 'Aktif hedef türü';
  static const goalTargetSection = 'Hedef adedi';
  static const goalRangeSection = 'Nota aralığı';
  static const goalMinMidi = 'En düşük nota';
  static const goalMaxMidi = 'En yüksek nota';
  static const goalSave = 'Kaydet';
  static const appUpdateSection = 'Uzaktan güncelleme';
  static const appUpdateHint =
      'Telefonda indir/kur yok. PC (Tailscale): fast-phone -Project music -Wireless. '
      'İlk kez: phone-adb-setup.ps1 (USB).';
  static const goalNone = 'Hedef yok';
  static const goalActive = 'Aktif hedef';
  static const goalCompletedTitle = 'Hedef tamamlandı';
  static const goalCompletedTarget = 'deneme';
  static const goalMedian = 'Süre medyanı';
  static const goalWrong = 'Yanlış toplam';
  static const goalBestStreak = 'En uzun doğru seri';
  static const goalPerMidi = 'Bu dönemde notaya göre';
  static const goalClose = 'Tamam';
  static const goalPracticeTime = 'Bu dönem toplam düşünme süresi';

  static const guitarMcqTitle = 'Gitarda nota ne?';
  static const guitarMcqDesc = 'Vurgulanan perdenin nota adını seç.';
  static const guitarFindTitle = 'Gitarda notayı bul';
  static const guitarFindDesc =
      'Gösterilen notayı fretboard üzerinde bul ve dokun.';
  static const exerciseGuitarMcq = 'gitar_mcq';
  static const exerciseGuitarFind = 'gitar_bul';
  static const guitarTapHint = 'Fretboard üzerinde bir perde seç.';
  static const guitarAllCorrectShown =
      'Yanlış seçim. Tüm doğru perdeler yeşil ile gösterildi.';

  static const guitarPlayTitle = 'Gitarda notayı çal';
  static const guitarPlayDesc =
      'Hedef notayı kendi gitarından çal; mikrofon notayı algılar.';
  static const exerciseGuitarPlay = 'gitar_cal';
  static const guitarPlayMicHint =
      'Mikrofon otomatik açılır; hedef notayı birkaç saniye net ve tek başına çal.';
  static const guitarPlayListening = 'Dinleniyor…';
  static const guitarPlayIdle = 'Dinleme kapalı';
  static const guitarPlayStart = 'Dinlemeyi başlat';
  static const guitarPlayStop = 'Dinlemeyi durdur';
  static const guitarPlayDenied = 'Mikrofon izni gerekli.';
  static const micPermissionRationale =
      'Akort ve “notayı çal” için mikrofon yalnızca cihazında işlenir; kayıt sunucuya gönderilmez.';
  static const clearStatsConfirmTitle = 'İstatistikleri sıfırla?';
  static const clearStatsConfirmBody =
      'Tüm deneme geçmişi silinir. Bu işlem geri alınamaz.';
  static const clearStatsConfirmOk = 'Sıfırla';
  static const cancel = 'İptal';
  static const guitarRangeHint =
      'Gitar modları, Hedef ekranındaki nota aralığına göre filtrelenir.';
  static const goalRangeStaffNote =
      'Porte alıştırmaları sabit aralıkta (kalın Mi2–1. tel Si4, gitar yazımı). Bu ayar yalnızca gitar modlarını etkiler.';
  static const guitarRangeEmptyTitle = 'Bu aralıkta perde yok';
  static const guitarRangeEmptyBody =
      'Hedef ekranından nota aralığını genişlet veya kaydet. Gitar modları bu aralığa göre filtrelenir.';
  static const guitarRangeEmptyBack = 'Ana menüye dön';
  static const guitarPlayDetected = 'Algılanan';
  static const guitarPlayPreview = 'Hedef sesini dinle';
  static const guitarPlayChangeTarget = 'Nota seç';
  static const guitarPlayPickNoteTitle = 'Çalacağın notayı seç';
  static const guitarPlayInTuneHint = 'İbre ortada — hedefe yakınsın';

  static const tunerTitle = 'Akort';
  static const tunerDesc =
      'Standart akort; mikrofon açılır, tel yumuşatılmış algı ile seçilir, A4 referansını ayarla.';
  static const tunerStringLine = 'Tel';
  static const tunerMicActive = 'Mikrofon açık';
  static const tunerMicResume = 'Dinlemeyi aç';
  static const tunerTargetHz = 'Hedef';
  static const tunerDetected = 'Algılanan';
  static const tunerCents = 'Sapma (sent)';
  static const tunerFlat = 'pes';
  static const tunerSharp = 'diya';
  static const tunerInTune = 'tam';
  static const tunerRefA4 = 'La4 referansı (Hz)';
  static const tunerPlayRef = 'Referans tonu çal';
  static const tunerManualOn = 'Manuel tel seçimi';
  static const tunerAutoOn = 'Otomatik tel algılama';
  static const tunerSwitchManual = 'Manuel';
  static const tunerSwitchAuto = 'Otomatik';

  static const practiceModePlacement = 'Yerleşim pratiği';
  static const practiceModeMcq = 'Tanıma pratiği';
  static const practiceModeInterval = 'Aralık pratiği';
  static const practiceModeChord = 'Akor pratiği';
  static const practiceModeScale = 'Gam pratiği';
  static const landingPreviewTitle = 'Bu alıştırmada';
  static const scaleSelectedNotesTitle = 'Seçilen notalar';

  static const soundOn = 'Ses açık';
  static const soundOff = 'Ses kapalı';
  static const soundHint = 'Uygulama sesleri ve gitar önizlemesi';
  static String statsNoteEncounters(int n) => '$n karşılaşma';
  static String statsNoteSectionCount(int n) => '$n nota';
  static const statsNotePickerHint =
      'Hedef seçici bu notada son 2 denemeye bakar';
  static const emptyStateHint = 'İlk denemen burada görünecek.';

  static const ob1Title = 'Hızlı başlangıç';
  static const ob1Body =
      'Portede yerleştir, çoktan seçmeli, gitar ve mikrofon egzersizleriyle doğal notaları pekiştir.';
  static const ob2Title = 'Hedef ve aralık';
  static const ob2Body =
      'Hedef ekranından deneme sayısı ve nota aralığını ayarla; ilerleme kayıtlı kalır.';
  static const ob3Title = 'Ses ve pratik';
  static const ob3Body =
      'Ana ekrandan sesi açıp kapatabilirsin. Geri bildirimde kısa titreşim ve ton kullanılır.';
  static const obNext = 'İleri';
  static const obStart = 'Başla';

  static const statsFilterAll = 'Tümü';
  static const statsFilterPlacement = 'Yerleştir';
  static const statsFilterMcq = 'Tanı';
  static const statsFilterGuitarMcq = 'Gitar tanı';
  static const statsFilterGuitarFind = 'Gitar bul';
  static const statsFilterGuitarPlay = 'Gitar çal';
  static const statsFilterInterval = 'Aralık';
  static const statsFilterScale = 'Gam';
  static const statsFilterChord = 'Akor';
}
