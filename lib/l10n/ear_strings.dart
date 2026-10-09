import '../audio/ear_audio_types.dart';

/// Kulak eğitimi modülünün tüm metinleri (tek yerden yönetim / ileride çeviri).
abstract final class EarStrings {
  // Genel
  static const moduleTitle = 'Kulaktan Akor Eğitimi';
  static const roadmapTitle = '12 Haftalık Yol Haritası';
  static const progressTitle = 'İlerleme & Zayıf Noktalar';
  static const progressTooltip = 'İlerleme ve zayıf noktalar';
  static const consolidationBadge = 'KONSOLİDASYON';
  static const nowBadge = 'ŞİMDİ';
  static const locked = 'Kilitli';
  static const active = 'Aktif';
  static const completed = 'Tamamlandı';
  static String weekLabel(int n) => '$n. Hafta';
  static String weekLockedSnack(int n) =>
      '$n. hafta kilitli — önce ${n - 1}. haftanın barajını geç.';
  static String streakDays(int n) => '$n gün';
  static const streakTooltip = 'Üst üste pratik yapılan gün sayısı';

  // Günlük kart
  static String dailyBadge(int week) => 'BUGÜNKÜ ANTRENMAN • ${weekLabel(week).toUpperCase()}';
  static const dailyBody = '10 soruluk kısa tur: günde 10 dakika, haftada 2 saatten etkilidir.';
  static const dailyDone = 'Bugünkü turu tamamladın! İstersen bir tur daha.';
  static const startNow = 'Başla';
  static const oneMore = 'Bir tur daha';

  // Tekrar kartı
  static const reviewTitle = 'Aralıklı Tekrar';
  static String reviewDue(int n) => '$n konu tekrar zamanı geldi';
  static const reviewNone = 'Bugün tekrar bekleyen konu yok 🎉';
  static const reviewBody = 'Unutma eğrisi kırılmadan zorlandığın sesleri yeniden dinle.';
  static const reviewStart = 'Tekrar et';
  static const reviewSessionTitle = 'Aralıklı Tekrar';

  // Hafta detayı
  static String weekDetailTitle(int n) => '${weekLabel(n)} Detayı';
  static const reflectionTooltip = 'Haftalık öz değerlendirme';
  static const exercisesTitle = 'Egzersizler';
  static String exerciseMeta(int count) => '$count soru • Kör dinleme';
  static const mixedFrom = 'Karışık: ';
  static const gateTitle = 'Hafta Barajı';
  static const gateDoneTitle = 'Hafta barajı geçildi!';
  static const gateAccuracy = 'Son 3 turun ortalaması';
  static const gateQuestions = 'Toplam soru';
  static const gateDays = 'Pratik yapılan gün';
  static const gateDaysHint =
      'Dağıtılmış pratik: aynı hafta içinde farklı günlerde çalışmak kalıcılığı artırır.';
  static const bossSubtitle = '15 soru • 3 can • Yanlışta can gider';
  static const bossClearedBadge = 'Boss yenildi';
  static const demoTooltip = 'Tını örneğini dinle';
  static const theoryTitle = 'Bu haftanın fikri';

  // Ders ekranı
  static const lessonBadge = 'DERS';
  static const lessonCtaTitle = 'Dersi Oku';
  static const lessonCtaSubtitle = 'Alıştırmalara başlamadan önce bu haftanın konusunu öğren';
  static const lessonCtaDoneSubtitle = 'Okundu — tekrar bakmak için dokun';
  static String lessonStepsMeta(int n) => '$n adım • ~${(n * 0.6).ceil() + 1} dk';
  static const lessonListen = 'Dinle';
  static const lessonKeyIdea = 'AKILDA TUT';
  static const lessonTerms = 'YENİ TERİMLER';
  static const lessonExamples = 'ÖRNEKLER';
  static const lessonTryThis = 'ŞİMDİ DENE';
  static const lessonCompareTitle = 'KARŞILAŞTIR';
  static const lessonCompareHint = 'İkisini art arda dinle, farkı tek kelimeyle söyle.';
  static const glossaryTitle = 'Terim Sözlüğü';
  static String glossarySubtitle(int n) => 'Bu haftaya kadar öğrendiğin $n terim';
  static const lessonStartPractice = 'Alıştırmalara Başla';
  static const lessonWarmupTitle = 'Hızlı Kontrol';
  static const lessonWarmupSubtitle = 'Puanlanmaz — sadece hazır olduğunu görelim';
  static String lessonWarmupDone(int correct, int total) =>
      '$correct/$total doğru — hazırsın! 🎉';

  // Quiz
  static const replay = 'Tekrar dinle';
  static const playing = 'Çalıyor…';
  static const tapToListen = 'Dinlemek için dokun';
  static const playTogether = 'Birlikte çal';
  static const playArpeggio = 'Arpej çal';
  static const playBassOnly = 'Bası ayrı dinle';
  static const continueLabel = 'Devam';
  static const finishLabel = 'Sonuçları gör';
  static const correctTitle = 'Doğru!';
  static const wrongTitle = 'Tam değil';
  static String correctAnswerIs(String label) => 'Doğrusu: $label';
  static String yourAnswer(String label) => 'Senin seçimin: $label';
  static const compareHint = 'Seçeneklere dokunarak seslerini karşılaştır.';
  static const compareFretHint = 'Perdelere dokunarak notaları karşılaştır.';
  static const contrastTitle = 'FARKI NASIL DUYARSIN?';
  static const listenYours = 'Seçtiğin';
  static const listenCorrect = 'Doğrusu';
  static String comboToast(int n) => '$n doğru üst üste! 🔥';
  static const soundOffTitle = 'Ses kapalı';
  static const soundOffBody = 'Kulak eğitimi için sesi açman gerekiyor.';
  static const soundOn = 'Sesi aç';
  static const exitTitle = 'Turdan çıkılsın mı?';
  static const exitBody = 'Bu turdaki ilerlemen kaydedilmeyecek.';
  static const exitConfirm = 'Çık';
  static const exitCancel = 'Devam et';
  static const closeTooltip = 'Turdan çık';
  static String questionCounter(int i, int n) => '$i / $n';
  static String heartsLabel(int n) => '$n can kaldı';
  static const keyboardHint = '1–9: seç · Boşluk: dinle · Enter: devam';
  static const openString = 'Açık';
  static String stringLabel(int s) => s == 6 ? '6. tel · Kalın Mi' : '5. tel · La';
  static String fretPosition(int string, int fret) =>
      '$string. tel ${fret == 0 ? 'açık' : '$fret. perde'}';

  // Soru metinleri
  static const intervalPrompt = 'Çalan aralık hangisi?';
  static const intervalHint = 'Önce mırıldan, sonra karar ver';
  static const intervalPromptDescending = 'Alçalan aralık (↓) hangisi?';
  static const intervalHintDescending =
      'Üst notadan aşağı iniyor — alçalan referans şarkını düşün';
  static const chordPrompt = 'Akorun rengi ne?';
  static const chordHint = 'Güneşli mi, gölgeli mi, açık tını mı?';
  static const cadencePrompt = 'Akorlar nereye bağlandı?';
  static const cadenceHint = 'Evden uzaklaşma, gerilim veya çöküş hissini dinle';
  static const bassPrompt = 'Bas notayı klavyede bul';
  static const bassHint = 'Bası mırıldan, sonra perdelerde dene';
  static const rhythmPrompt = 'Akorlar kaç vuruşta bir değişti?';
  static const rhythmHint = 'İçinden 1-2-3-4 diye sabit tempo tut, her değişimde elini vur';

  static String rhythmOptionTitle(int beats) => switch (beats) {
        2 => '2 Vuruşta Bir (Yarım Ölçü)',
        8 => '8 Vuruşta Bir (2 Ölçü)',
        _ => '4 Vuruşta Bir (1 Tam Ölçü)',
      };

  static String rhythmOptionSubtitle(int beats) => switch (beats) {
        2 => 'Hızlı: hem "1"de hem "3"te yeni akor',
        8 => 'Çok geniş: aynı akor iki ölçü boyunca sürer',
        _ => 'Geniş: her "1"de yeni akor',
      };

  static const inversionPrompt = 'Basta hangi nota var: kök mü, 3\'lü mü, 5\'li mi?';
  static const inversionHint = '"Bası ayrı dinle" ile en pes sesi mırıldan, sonra akorla karşılaştır';

  static String inversionOptionTitle(int inversion) => switch (inversion) {
        1 => '1. İnversiyon (bas 3\'lü)',
        2 => '2. İnversiyon (bas 5\'li)',
        _ => 'Kök Pozisyon (bas kök)',
      };

  static String inversionOptionSubtitle(int inversion, String chordName, String bassNote) =>
      switch (inversion) {
        1 => '$chordName, basta $bassNote • kararlı ama hafif',
        2 => '$chordName, basta $bassNote • asılı, çözülmemiş',
        _ => '$chordName, basta $bassNote • tam oturmuş',
      };

  static const degreePrompt = 'Ev kuruldu. Son çalan nota kaçıncı derece?';
  static const degreeHint = 'Notayı mırıldan ve eve (Do) nasıl dönmek istediğini hisset';
  static const degreeResolve = 'Eve çözülüşünü dinle';

  static String degreeTitle(int d) => switch (d) {
        1 => '1 · Do (ev)',
        2 => '2 · Re',
        3 => '3 · Mi',
        4 => '4 · Fa',
        5 => '5 · Sol',
        6 => '6 · La',
        _ => '7 · Si',
      };

  static String degreeSubtitle(int d) => switch (d) {
        1 => 'Tamamen oturmuş, hiçbir yere gitmek istemez',
        2 => 'Evin bir adım üstü, hafif askıda',
        3 => 'Sakin ve parlak; evin majör rengi',
        4 => 'Aşağı, Mi\'ye inmek ister',
        5 => 'Sağlam ama evden uzak, açık',
        6 => 'Hafif hüzünlü, Sol\'e ya da Do\'ya gitmek ister',
        _ => 'Eve yarım ses uzakta, yukarı çekilir',
      };

  static String degreeExplanation(int d) => switch (d) {
        1 => 'Do (1): Tonun evi. Çaldığında hiçbir gerilim kalmaz.',
        2 => 'Re (2): Eve bir tam ses yukarıda; genelde Do\'ya iner.',
        3 => 'Mi (3): Majör akorun 3\'lüsü; sakin ve dengeli, gamı "majör" yapan nota.',
        4 => 'Fa (4): Mi\'ye yarım ses yukarıda durur ve oraya inmek ister — tonun iki mıknatısından biri.',
        5 => 'Sol (5): Dominantın kökü; sağlam ama evden uzak, yukarı Do\'ya da aşağı Do\'ya da gidebilir.',
        6 => 'La (6): İlgili minörün evi; hafif hüzünlü, Sol\'e ya da yukarı Do\'ya çözülür.',
        _ => 'Si (7): Yönlendirici ses; eve yarım ses uzakta, yukarı Do\'ya güçlü bir çekim yaratır.',
      };

  /// Doğru aralık için çapa şarkılar. [descending] ise önce alçalan örnekler
  /// verilir — alçalan aralık kulakta ayrı bir "şekil"dir.
  static String intervalReference(EarIntervalType t, {bool descending = false}) {
    final up = _intervalUp(t);
    final down = _intervalDown(t);
    final size = '${t.semitones} yarım ses = aynı telde ${t.semitones} perde.';
    return descending
        ? '$size\n↓ Alçalan: $down\n↑ Yükselen: $up'
        : '$size\n↑ Yükselen: $up\n↓ Alçalan: $down';
  }

  /// Şarkı çapası alanındaki kısa örnek (ipucu metni).
  static String anchorExample(EarIntervalType t, {required bool descending}) =>
      descending
          ? switch (t) {
              EarIntervalType.minor2 => 'Für Elise açılışı',
              EarIntervalType.major2 => 'Mary Had a Little Lamb ("Ma-ry")',
              EarIntervalType.minor3 => 'Küçük Kurbağa ("Kü-çük")',
              EarIntervalType.major3 => 'Beethoven 5. Senfoni',
              EarIntervalType.perfect4 => 'İstiklal Marşı açılışının tersi',
              EarIntervalType.perfect5 => 'Çakmaktaşlar teması',
              EarIntervalType.octave => 'İyi ki Doğdun sıçramasının tersi',
            }
          : switch (t) {
              EarIntervalType.minor2 => 'Jaws teması',
              EarIntervalType.major2 => 'İyi ki Doğdun ("İ-yi – ki")',
              EarIntervalType.minor3 => 'Hatırla Sevgili ("Ha-tır")',
              EarIntervalType.major3 => 'Arı Vız Vız ("A-rı")',
              EarIntervalType.perfect4 => 'İstiklal Marşı ("Kork-ma")',
              EarIntervalType.perfect5 => 'Yaşasın Okulumuz ("Ya-şa-sın")',
              EarIntervalType.octave => 'İyi ki Doğdun ("İ-yi ki DOĞ-dun")',
            };

  static String _intervalUp(EarIntervalType t) => switch (t) {
        EarIntervalType.minor2 =>
          '"Jaws" filminin köpekbalığı teması ("da-dum, da-dum"), "Pembe Panter" teması.',
        EarIntervalType.major2 =>
          '"İyi ki Doğdun"un açılışı ("İ-yi – ki"), "Frère Jacques" ("Uyuyor musun?").',
        EarIntervalType.minor3 =>
          '"Hatırla Sevgili" ("Ha – tır"), "Seven Nation Army" riffi (stadyumlardaki "oo-oo-oo"), "Smoke on the Water" riffinin ilk iki notası.',
        EarIntervalType.major3 =>
          '"Arı Vız Vız Vız" çocuk şarkısının açılışı ("A – rı"), majör arpejin ilk iki notası (Do – Mi).',
        EarIntervalType.perfect4 =>
          'İstiklal Marşı açılışı ("Kork – ma"), Düğün Marşı, Harry Potter ana teması.',
        EarIntervalType.perfect5 =>
          '"Yaşasın Okulumuz" / "Daha Dün Annemizin" ("Ya-şa – sın"), "Star Wars" ana teması.',
        EarIntervalType.octave =>
          '"İyi ki Doğdun"un 3. dizesi ("İ-yi ki – DOĞ-dun"), "Somewhere Over the Rainbow".',
      };

  static String _intervalDown(EarIntervalType t) => switch (t) {
        EarIntervalType.minor2 =>
          'Beethoven "Für Elise" açılışı (Mi – Re♯).',
        EarIntervalType.major2 =>
          '"Mary Had a Little Lamb" ("Ma – ry"); gitarda aynı telde 2 perde aşağı.',
        EarIntervalType.minor3 =>
          '"Küçük Kurbağa" ("Kü – çük"), uzaktan birine seslenirken ("Ah – met!"), "Hey Jude" ("Hey – Jude").',
        EarIntervalType.major3 =>
          'Beethoven 5. Senfoni ("ta-ta-ta-TAM"), klasik "ding-dong" kapı zili.',
        EarIntervalType.perfect4 =>
          'Gitarda 5. tel boş La\'dan 6. tel boş Mi\'ye iniş; İstiklal Marşı açılışının tersi.',
        EarIntervalType.perfect5 =>
          '"Çakmaktaşlar" (The Flintstones) teması ("Flint – stones"); "Yaşasın Okulumuz" açılışının tersi.',
        EarIntervalType.octave =>
          'Gitarda 4. tel 2. perde Mi\'den 6. tel boş Mi\'ye iniş: aynı nota, sadece kalınlaşır.',
      };

  static String chordExplanation(EarChordQuality q) => switch (q) {
        EarChordQuality.major =>
          'Majör = kök + büyük 3\'lü + tam 5\'li. Büyük 3\'lü akoru "güneşli" yapar.',
        EarChordQuality.minor =>
          'Minör = kök + küçük 3\'lü + tam 5\'li. Tek fark 3\'lünün yarım ses pes olması.',
        EarChordQuality.sus2 =>
          'Sus2\'de 3\'lü yok, yerine 2\'li var: ne majör ne minör — asılı, açık bir tını.',
        EarChordQuality.power =>
          'Power chord sadece kök + 5\'li: 3\'lü olmadığı için rengi nötr, distorsiyonda temiz.',
        EarChordQuality.dominant7 =>
          'Dominant 7 = majör + küçük 7\'li. Çözülmek isteyen blues gerilimi (E7 → Am).',
        EarChordQuality.minor7 =>
          'Minör 7 = minör + küçük 7\'li. Hüznü yumuşatan kadife, akustik pop tınısı.',
      };

  static String cadenceExplanation(EarCadenceType c) => switch (c) {
        EarCadenceType.I_IV =>
          'I → IV: Ev akorundan 4. dereceye — açılan, genişleyen bir his.',
        EarCadenceType.I_V =>
          'I → V: 5. dereceye gidiş gerilim yaratır; kulak eve dönmeyi bekler.',
        EarCadenceType.i_VI =>
          'i → VI: Minör tonikten majör 6\'ya iniş — Anadolu popunun duygusal çöküşü.',
        EarCadenceType.V7_i =>
          'V7 → i: Harmonik minörde tizleşen 7. derece (Sol#) La\'ya çekilir; güçlü bir karar.',
        EarCadenceType.I_V_vi_IV =>
          'I–V–vi–IV: Dünya popunun en yaygın döngüsü; 4 akorda ev → gerilim → hüzün → açılış.',
        EarCadenceType.V_vi =>
          'V → vi: Kulak otantik kadansı (V→I) beklerken beklenmedik biçimde vi\'ye sapılır — "yanıltıcı" adı buradan gelir.',
        EarCadenceType.IV_I =>
          'IV → I: Otantik kadanstan (V→I) daha yumuşak bir çözülüş; kilise ilahilerinin "a-min" kapanışına adını veren "amin kadansı".',
      };

  static String bassExplanation(List<String> positions) =>
      'Bu nota klavyede: ${positions.join(' veya ')}. Aynı perde değil, aynı ses önemli.';

  static String rhythmExplanation(int beats) => switch (beats) {
        2 => 'Akorlar her 2 vuruşta bir değişti: hem "1"de hem "3"te yeni akor (yarım ölçü).',
        8 => 'Akorlar her 8 vuruşta bir değişti: her akor iki tam ölçü sürdü (yavaş şarkılarda sık).',
        _ => 'Akorlar her 4 vuruşta bir değişti: her "1"de yeni akor (bir tam ölçü).',
      };

  static String inversionExplanation({
    required int inversion,
    required String chordName,
    required String bassName,
  }) =>
      switch (inversion) {
        1 => '$chordName, basta $bassName: bas kök yerine 3\'lüyü çaldı (1. inversiyon). Bas yürüyüşlerinin en sık kullandığı hâl.',
        2 => '$chordName, basta $bassName: bas 5\'liyi çaldı (2. inversiyon). Basla üstü arasında 4\'lü oluştuğu için asılı duyulur.',
        _ => '$chordName, basta $bassName: en pes nota akorun kendi kökü (kök pozisyon).',
      };

  // Sonuç ekranı
  static const summaryPerfect = 'Kusursuz tur!';
  static const summaryGreat = 'Harika iş!';
  static const summaryKeepGoing = 'İyi gidiyorsun';
  static const summaryTryAgain = 'Pratik devam';
  static const bossWonTitle = 'Boss yenildi! 👑';
  static const bossLostTitle = 'Boss bu sefer kazandı';
  static String summaryAccuracy(int pct) => '%$pct doğruluk';
  static const statCorrect = 'Doğru';
  static const statTime = 'Süre';
  static const statAvgResponse = 'Ort. cevap';
  static const statBestCombo = 'En iyi seri';
  static String seconds(num s) => '${s.toStringAsFixed(s < 10 ? 1 : 0)} sn';
  static String minutesSeconds(int totalSec) =>
      totalSec < 60 ? '$totalSec sn' : '${totalSec ~/ 60} dk ${totalSec % 60} sn';
  static const sessionWeakTitle = 'Bu turda zorlandıkların';
  static const sessionWeakBody = 'Bunlar aralıklı tekrar kuyruğuna eklendi.';
  static const gateProgressTitle = 'Hafta barajına ilerleme';
  static String weekUnlocked(int n) => '${weekLabel(n)} açıldı!';
  static const weekCompletedBanner = 'Bu haftanın barajını geçtin 🎉';
  static String thresholdNote(int pct) => 'Baraj: son 3 turun ortalaması en az %$pct';
  static const reviewNotCounted = 'Tekrar turları hafta barajına sayılmaz; hafızayı tazeler.';
  static const playAgain = 'Tekrar oyna';
  static const done = 'Bitti';
  static const reflectNow = 'Haftayı değerlendir';
  static const saving = 'Kaydediliyor…';

  // İlerleme ekranı
  static const statStreak = 'GÜN SERİ';
  static const statWeeksDone = 'HAFTA';
  static const statOverall = 'DOĞRULUK';
  static String totalSummary(int q, int w) => 'Toplam $q soru • $w hafta tamamlandı';
  static const weakTitle = 'Zayıf Nokta Radarı';
  static const weakBody = 'Son turlarda en çok karıştırdığın sesler. Dokun ve hedefli pratik yap.';
  static const weakEmpty = 'Henüz yeterli veri yok. Birkaç tur tamamla!';
  static String errorCount(int n) => '$n hata';
  static const practiceThis = 'Çalış';
  static const recentTitle = 'Son Turlar';
  static const recentEmpty = 'Henüz tamamlanmış tur yok.';
  static const curriculumStatus = 'Müfredat Durumu';

  // Gelişim eğrisi (doğruluk trendi)
  static const trendTitle = 'Gelişim Eğrisi';
  static String trendSubtitle(int n) => 'Son $n turun doğruluk yüzdesi';
  static const trendEmpty = 'En az 2 tur tamamladığında burada trend çizgin görünecek.';
  static String trendDeltaUp(int pct) => '▲ %$pct';
  static String trendDeltaDown(int pct) => '▼ %$pct';
  static const trendDeltaFlat = 'Değişim yok';
  static const trendFirst = 'İlk';
  static const trendLatest = 'Son';

  // Pratik takvimi (streak heatmap)
  static const heatmapTitle = 'Pratik Takvimi';
  static String heatmapSubtitle(int days) => 'Son $days gün';
  static const heatmapLegendLess = 'Az';
  static const heatmapLegendMore = 'Çok';
  static String weekDoneLine(int acc, int q) => 'Tamamlandı • Son 3 tur ort. %$acc • $q soru';
  static String weekActiveLine(int acc, int q, int minQ) =>
      'Aktif • Son 3 tur ort. %$acc • $q/$minQ soru';

  // Konu bazında başarı
  static const subtypeAccTitle = 'Konu Bazında Başarı';
  static const subtypeAccBody =
      'Son turlarda her konudaki doğru oranın. Kırmızılar en çok çalışman gerekenler.';
  static const subtypeAccEmpty = 'Konu bazında başarı için birkaç tur daha tamamla.';
  static String subtypeAccMeta(int correct, int attempts) => '$correct/$attempts doğru';

  // Kişisel şarkı çapaları
  static const anchorsTitle = 'Şarkı Çapalarım';
  static const anchorsBody =
      'Her aralık için kendi bildiğin bir şarkıyı yaz. Yanlış yaptığında önce senin şarkın gösterilir.';
  static const anchorsEdit = 'Şarkılarımı düzenle';
  static const anchorsSave = 'Kaydet';
  static const anchorsSaved = 'Şarkı çapaların kaydedildi';
  static const anchorsUp = '↑ Yükselen';
  static const anchorsDown = '↓ Alçalan';
  static String anchorsHint(String example) => 'Örn. $example';
  static String anchorsCount(int n) => n == 0 ? 'Henüz şarkı eklemedin' : '$n şarkı kayıtlı';
  static const yourSong = 'Senin şarkın';
  static const addYourSong = 'Kendi şarkını ekle';
  static const weekLockedLine = 'Kilitli • Önceki haftayı tamamla';
  static String modeLabel(String mode) => switch (mode) {
        'boss' => 'Boss',
        'review' => 'Tekrar',
        _ => 'Pratik',
      };

  // Öz değerlendirme
  static const reflectionTitle = 'Haftalık Öz Değerlendirme';
  static const reflectionConfidence = 'Bu haftanın konusunda kendini ne kadar güvende hissediyorsun?';
  static const reflectionHardest = 'En çok nerede zorlandın?';
  static const reflectionSave = 'Kaydet';
  static const reflectionSaved = 'Değerlendirmen kaydedildi';
  static String reflectionBest(int pct) => 'En iyi tur: %$pct';
  static const confidenceLow = 'Hiç';
  static const confidenceHigh = 'Tamamen';
  static const hardestOptions = [
    'Aralık renkleri (majör / minör)',
    '1. vuruş basını yakalama',
    'Akor geçiş hızı',
    'Teoriyi gitarda bulma',
    'Zorlanmadım, her şey netti',
  ];
}
