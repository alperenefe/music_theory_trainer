import '../audio/ear_audio_types.dart';
import '../audio/ear_sound.dart';
import 'ear_exercise_kind.dart';

/// Bir haftanın dersindeki tek bir öğretim adımı: başlık + açıklama,
/// isteğe bağlı dinlenebilir bir ses örneğiyle.
///
/// [WeekTheoryCard]'daki tek cümlelik ipucundan farklı olarak, ders ekranı
/// bu noktaları sırayla göstererek haftanın konusunu gerçekten *anlatır*.
final class LessonPoint {
  const LessonPoint({
    required this.heading,
    required this.body,
    this.sound,
    this.soundLabel,
    this.compareSound,
    this.compareLabel,
    this.keyIdea,
    this.terms = const {},
    this.examples = const [],
    this.tryThis,
    this.opensAnchorEditor = false,
  });

  final String heading;
  final String body;
  final EarSound? sound;
  final String? soundLabel;

  /// İsteğe bağlı ikinci ses: [sound] ile art arda dinlenip karşılaştırılır
  /// (A/B). Kulak, iki şeyi yan yana duyunca farkı çok daha hızlı öğrenir.
  final EarSound? compareSound;
  final String? compareLabel;

  /// Noktanın tek cümlelik özü — okuyucu başka hiçbir şeyi hatırlamasa bile
  /// bunu hatırlamalı.
  final String? keyIdea;

  /// Bu noktada ilk kez geçen terimler → tek cümlelik tanım.
  final Map<String, String> terms;

  /// Doğrulanmış somut örnekler (şarkı açılışları, gitar kalıpları vb.).
  final List<String> examples;

  /// Okuduktan hemen sonra yapılacak tek, somut eylem.
  final String? tryThis;

  /// true: kartta kişisel şarkı çapalarını düzenleme düğmesi gösterilir.
  final bool opensAnchorEditor;
}

/// [weekNumber] dahil o haftaya kadar derslerde tanıtılmış tüm terimler,
/// ilk tanımlandıkları sırayla (sözlük için).
Map<String, String> earGlossaryUpTo(int weekNumber) {
  final out = <String, String>{};
  for (final w in earCurriculumWeeks) {
    if (w.weekNumber > weekNumber) break;
    for (final p in w.lesson) {
      for (final e in p.terms.entries) {
        out.putIfAbsent(e.key, () => e.value);
      }
    }
  }
  return out;
}

final class MasteryGate {
  const MasteryGate({
    this.accuracyThreshold = 0.85,
    this.minQuestions = 25,
    this.minDaysActive = 7,
  });

  final double accuracyThreshold;
  final int minQuestions;
  final int minDaysActive;

  Map<String, Object?> toJson() => {
        'accuracyThreshold': accuracyThreshold,
        'minQuestions': minQuestions,
        'minDaysActive': minDaysActive,
      };

  static MasteryGate fromJson(Map<String, Object?> j) {
    double nd(Object? v, double d) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      return d;
    }

    int ni(Object? v, int d) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return d;
    }

    return MasteryGate(
      accuracyThreshold: nd(j['accuracyThreshold'], 0.85),
      minQuestions: ni(j['minQuestions'], 25),
      minDaysActive: ni(j['minDaysActive'], 7),
    );
  }
}

final class EarWeek {
  const EarWeek({
    required this.weekNumber,
    required this.title,
    required this.subtitle,
    required this.theoryBrief,
    required this.lesson,
    required this.exercises,
    required this.gate,
    this.isConsolidation = false,
    this.bossTitle,
  });

  final int weekNumber;
  final String title;
  final String subtitle;
  final String theoryBrief;

  /// Haftanın tam dersi: [EarLessonScreen]'de sırayla gösterilen, sesli
  /// örneklerle desteklenen öğretim adımları. Alıştırmalara başlamadan
  /// önce konuyu gerçekten anlatan kısım burasıdır.
  final List<LessonPoint> lesson;
  final List<EarExerciseKind> exercises;
  final MasteryGate gate;
  final bool isConsolidation;
  final String? bossTitle;
}

const earCurriculumWeeks = <EarWeek>[
  // ---------------------------------------------------------------- HAFTA 1
  EarWeek(
    weekNumber: 1,
    title: "Aralıklar & Downbeat Bası",
    subtitle: "Küçük 3'lü, büyük 3'lü, tam 5'li, oktav ve 1. vuruştaki bas",
    theoryBrief:
        "Aralığı sayarak değil, verdiği duyguyla tanı: büyük 3'lü gülümser, küçük 3'lü kaşlarını çatar, 5'li boş ve güçlü, oktav aynı notanın tizi.",
    lesson: [
      LessonPoint(
        heading: "Aralık ne demek?",
        body:
            "Aralık, iki nota arasındaki mesafedir. Ama kulak bu mesafeyi bir sayı olarak "
            "değil, bir “renk” ya da duygu olarak algılar. Bu yüzden aralıkları ezberleyerek "
            "değil, nasıl hissettirdiklerini tanıyarak öğreneceğiz. Aşağıdaki örnekte önce "
            "alttaki nota (kök), sonra üstteki nota çalıyor.",
        sound: IntervalSound(rootMidi: 45, interval: EarIntervalType.major3),
        soundLabel: "Bir aralık dinle (kök → üst nota)",
        terms: {
          "Aralık": "İki nota arasındaki mesafe; kulakta bir duygu/renk olarak duyulur.",
          "Yarım ses": "Batı müziğindeki en küçük adım. Gitarda tam olarak 1 perde.",
          "Kök": "Aralığın ya da akorun dayandığı, “ev” sayılan alt nota.",
        },
        keyIdea: "Aralığı sayarak değil, verdiği duyguyla tanırsın.",
        tryThis:
            "Gitarda 5. teli boş çal (La), ardından aynı telde 4. perdeyi çal. Duyduğun şey "
            "bir büyük 3'lü — 4 perde = 4 yarım ses.",
      ),
      LessonPoint(
        heading: "Bu haftanın 4 aralığı",
        body:
            "Bu müfredatın hedefi kulaktan akor çıkarmak ve akorlar 3'lü ile 5'lilerden "
            "kurulur. Bu yüzden, birçok kulak eğitimi rehberinin önerdiği gibi, birbirinden "
            "kolay ayrılan bu dört aralıkla başlıyoruz. Melodilerin adımları olan 2'liler "
            "4. haftada, akorlar oturduktan sonra gelecek. Aşağıdaki örnek aynı kökten "
            "dördünü sırayla çalar: küçük 3'lü, büyük 3'lü, tam 5'li, oktav.",
        sound: ScaleSound(notes: [45, 48, 45, 49, 45, 52, 45, 57], stepDurationMs: 520),
        soundLabel: "Dördünü sırayla dinle",
        examples: [
          "Küçük 3'lü — 3 yarım ses (3 perde): hüzünlü, içe kapanık",
          "Büyük 3'lü — 4 yarım ses (4 perde): aydınlık, gülümseyen",
          "Tam 5'li — 7 yarım ses (7 perde): boş, güçlü, kararlı",
          "Oktav — 12 yarım ses (12 perde): aynı notanın tizi",
        ],
        keyIdea: "İki duygulu aralık (3'lüler), iki duygusuz aralık (5'li ve oktav).",
      ),
      LessonPoint(
        heading: "Küçük 3'lü mü, büyük 3'lü mü?",
        body:
            "Bu ikisi arasındaki fark sadece 1 yarım ses, bu yüzden en çok karıştırılan "
            "çift budur. Rakamlara takılma; kendine tek bir soru sor: “Bu ses aydınlık mı, "
            "gölgeli mi?” Önce A'yı, sonra B'yi dinle ve farkı tek kelimeyle söyle.",
        sound: IntervalSound(rootMidi: 45, interval: EarIntervalType.major3),
        soundLabel: "Büyük 3'lü (aydınlık)",
        compareSound: IntervalSound(rootMidi: 45, interval: EarIntervalType.minor3),
        compareLabel: "Küçük 3'lü (gölgeli)",
        examples: [
          "Büyük 3'lü ↑: “Arı Vız Vız Vız” çocuk şarkısının açılışı (“A – rı”)",
          "Küçük 3'lü ↑: “Hatırla Sevgili” (“Ha – tır”), “Seven Nation Army” riffi (stadyumlardaki “oo-oo-oo”)",
          "Küçük 3'lü ↓: “Küçük Kurbağa” (“Kü – çük”), uzaktan birine seslenmek (“Ah – met!”)",
        ],
        keyIdea: "Büyük 3'lü gülümser, küçük 3'lü kaşlarını çatar.",
        tryThis:
            "A ve B'yi A-B-A-B sırasıyla dört kez dinle. Her seferinde sesli olarak "
            "“aydınlık” ya da “gölgeli” de. Sonra gözlerini kapatıp birini rastgele çal.",
      ),
      LessonPoint(
        heading: "Arpej çapası: elin zaten biliyor",
        body:
            "Gitar çalıyorsan bu iki aralığı zaten binlerce kez çaldın. Büyük 3'lü, majör "
            "akorun ilk iki notasıdır; küçük 3'lü, minör akorun ilk iki notasıdır. Bir 3'lü "
            "duyduğunda kendine “Bu bir majör akor mu başlatıyor, minör mü?” diye sor.",
        sound: ChordSound(rootMidi: 45, quality: EarChordQuality.major, arpeggio: true),
        soundLabel: "La majör arpej (ilk iki nota = büyük 3'lü)",
        compareSound: ChordSound(rootMidi: 45, quality: EarChordQuality.minor, arpeggio: true),
        compareLabel: "La minör arpej (ilk iki nota = küçük 3'lü)",
        terms: {
          "Arpej": "Akorun notalarını aynı anda değil, tek tek sırayla çalmak.",
        },
        examples: [
          "“Hatırla Sevgili”nin ilk kelimesi “Ha-tır-la” tam olarak La-Do-Mi, yani B'deki La minör arpejdir: “Ha – tır” küçük 3'lü, “tır – la” büyük 3'lü",
        ],
        keyIdea: "Büyük 3'lü = majör akorun başlangıcı, küçük 3'lü = minör akorun başlangıcı.",
      ),
      LessonPoint(
        heading: "Tam 5'li: boş ama güçlü",
        body:
            "Tam 5'li (7 yarım ses) en “temiz” duyulan aralıklardan biridir: iki notanın "
            "frekans oranı çok basittir (3:2), bu yüzden neredeyse hiç gerilim taşımaz. "
            "3'lülerin aksine bir duygu vermez — sadece sağlam ve boş durur. Rock'taki power "
            "chord'un sesi tam olarak budur.",
        sound: IntervalSound(rootMidi: 45, interval: EarIntervalType.perfect5),
        soundLabel: "Tam 5'liyi dinle",
        examples: [
          "↑ “Yaşasın Okulumuz” / “Daha Dün Annemizin” (“Ya-şa – sın”)",
          "↑ “Star Wars” ana temasının açılışı",
          "↓ “Çakmaktaşlar” (The Flintstones) teması (“Flint – stones”)",
        ],
        keyIdea: "Duygu vermeyen, boş ama güçlü bir ses duyuyorsan büyük ihtimalle 5'lidir.",
        tryThis:
            "6. teli boş çal (Mi) ve aynı anda 5. telin 2. perdesine bas (Si). Bu bir E5 "
            "power chord — iki notası arasındaki mesafe tam 5'li.",
      ),
      LessonPoint(
        heading: "Oktav: aynı nota, bir kat yukarıda",
        body:
            "Oktavda üstteki notanın frekansı alttakinin tam iki katıdır. Bu yüzden kulak onu "
            "başka bir nota olarak değil, aynı notanın tizi olarak duyar — iki notanın adı "
            "da aynıdır. Oktav ile 5'li sık karıştırılır; A ve B'yi karşılaştır.",
        sound: IntervalSound(rootMidi: 45, interval: EarIntervalType.octave),
        soundLabel: "Oktav (aynı isim)",
        compareSound: IntervalSound(rootMidi: 45, interval: EarIntervalType.perfect5),
        compareLabel: "Tam 5'li (başka nota)",
        examples: [
          "↑ “İyi ki Doğdun”un 3. dizesindeki büyük sıçrama (“İ-yi ki – DOĞ-dun”)",
          "↑ “Somewhere Over the Rainbow” (“Some – where”)",
          "Gitarda: 6. tel boş Mi ile 4. telin 2. perdesindeki Mi bir oktavdır",
        ],
        keyIdea: "İkinci nota “aynı isim” gibi geliyorsa oktav, “başka nota” gibi geliyorsa 5'li.",
      ),
      LessonPoint(
        heading: "Ardışık mı, birlikte mi?",
        body:
            "Bir aralık iki şekilde çalınabilir: notalar art arda (melodik) ya da aynı anda "
            "(armonik). Melodik dinleme mesafeyi, armonik dinleme rengi hissettirir. "
            "Araştırmalar ikisini erkenden birlikte çalışmanın daha iyi sonuç verdiğini "
            "gösteriyor. Birlikte çalındığında oktav tek ve kalın bir ses gibi kaynaşır, "
            "5'li ise iki ayrı ses olarak kalır.",
        sound: IntervalSound(rootMidi: 45, interval: EarIntervalType.perfect5, harmonic: true),
        soundLabel: "Tam 5'li birlikte",
        compareSound: IntervalSound(rootMidi: 45, interval: EarIntervalType.octave, harmonic: true),
        compareLabel: "Oktav birlikte",
        terms: {
          "Melodik aralık": "İki notanın art arda çalınması.",
          "Armonik aralık": "İki notanın aynı anda çalınması.",
        },
        keyIdea: "Alıştırmada emin olamazsan “Birlikte çal” düğmesine bas: renk daha net duyulur.",
      ),
      LessonPoint(
        heading: "En hızlı yöntem: şarkı çapası",
        body:
            "Kulak eğitimi kaynaklarının en çok önerdiği yöntem, her aralığı açılışı o "
            "aralıkla başlayan bir şarkıya bağlamaktır. Aralığı duyduğunda beynin şarkının "
            "devamını kendiliğinden tamamlar. Kendi bildiğin şarkılar, ezberlediğin bir "
            "listeden çok daha kalıcıdır. İkinci güçlü araç da sesindir: aralığı mırıldanmak "
            "kulağı en hızlı geliştiren alışkanlıklardan biridir.",
        keyIdea: "Kendi seçtiğin şarkı, ezberlediğin listeden daha kalıcı bir çapadır.",
        tryThis:
            "Bu dört aralığın her biri için açılışı o aralıkla başlayan, kendi bildiğin bir "
            "şarkı bul ve aşağıdaki düğmeyle kaydet. Yanlış yaptığında önce senin şarkın "
            "gösterilecek. Bir aralığı duyduğunda adını iki notaya bölerek mırıldan: "
            "“bü-YÜK” (alt nota, üst nota).",
        opensAnchorEditor: true,
      ),
      LessonPoint(
        heading: "1. vuruş (downbeat) bası",
        body:
            "Şimdi kulağını farklı bir hedefe çevir: bas gitar. Bas gitarda her nota eşit "
            "önemde değildir. Akorun değiştiği ilk vuruşta (downbeat) çalan, en gövdeli ve en "
            "uzun çınlayan ses genellikle o anki akorun köküdür. Aradaki geçiş notalarına ve "
            "süslemelere takılma.",
        sound: NoteSound(45),
        soundLabel: "Kök bas notasını dinle",
        terms: {
          "Vuruş": "Müziğin düzenli nabzı; ayağınla tuttuğun tempo.",
          "Ölçü": "Vuruşların gruplandığı birim; pop müzikte genelde 4 vuruş.",
          "Downbeat": "Ölçünün ilk ve en güçlü vuruşu (“1”).",
        },
        keyIdea: "Akorun adı, çoğunlukla 1. vuruşta basın çaldığı notadır.",
        tryThis:
            "Sevdiğin bir şarkıyı aç, ayağınla 1-2-3-4 say. Sadece “1” dediğin anda basta "
            "duyduğun notayı mırıldan.",
      ),
      LessonPoint(
        heading: "Bu hafta nasıl çalışacaksın",
        body:
            "Her tur 10 soru. Günde bir ya da iki kısa tur, haftada bir kez uzun bir oturumdan "
            "çok daha etkilidir: kısa ve sık tekrar, bilginin kalıcı hafızaya geçmesini sağlar. "
            "Yanlış yaptığında çıkan “Farkı nasıl duyarsın?” kutusunu oku ve iki sesi art arda "
            "dinle. %100'ü bekleme: kaynaklar %80 civarında bir sonraki adıma geçmenin "
            "ilerlemeyi hızlandırdığını söylüyor.",
        keyIdea: "Her gün kısa tur, haftada bir uzun turdan daha etkilidir.",
      ),
    ],
    exercises: [EarExerciseKind.intervalBlind],
    gate: MasteryGate(accuracyThreshold: 0.80, minQuestions: 20, minDaysActive: 3),
    bossTitle: "Hafta 1 Boss: 10/10 Temel Aralık Avı",
  ),
  // ---------------------------------------------------------------- HAFTA 2
  EarWeek(
    weekNumber: 2,
    title: "Majör Gam & Harmonik Ritim",
    subtitle: "T-T-Y-T-T-T-Y formülü, alçalan aralıklar ve akorların değişim hızı",
    theoryBrief:
        "Majör gamda iki yarım ses adımı var (3-4 ve 7-8) ve bunlar tonun “mıknatısları”. Akorlar çoğu şarkıda 4 ya da 2 vuruşta bir değişir.",
    lesson: [
      LessonPoint(
        heading: "Majör gam formülü: T-T-Y-T-T-T-Y",
        body:
            "Majör gam, tam (T) ve yarım (Y) adımların sabit bir dizilimidir: "
            "Tam-Tam-Yarım-Tam-Tam-Tam-Yarım. Bu formül her tonda aynıdır. Gamın ilk notası "
            "tonun “evi”dir; gamı çıkıp inince son notanın ilk notaya oturduğunu hissedersin.",
        sound: ScaleSound(notes: [48, 50, 52, 53, 55, 57, 59, 60]),
        soundLabel: "Do majör gamı (T-T-Y-T-T-T-Y)",
        terms: {
          "Gam": "Belirli bir formülle sıralanmış notalar dizisi.",
          "Tam ses": "İki yarım ses. Gitarda 2 perde.",
          "Tonik": "Tonun evi; gamın ilk ve son notası.",
        },
        keyIdea: "Majör gam = T-T-Y-T-T-T-Y; formül her tonda aynıdır.",
        tryThis:
            "5. telin 3. perdesinden (Do) başla ve tek telde 2-2-1-2-2-2-1 perde atlayarak "
            "15. perdeye kadar çık. Elinin düzensiz adımları, kulağının duyduğu farkın ta "
            "kendisi.",
      ),
      LessonPoint(
        heading: "Eve çekilen nota: 7. derece",
        body:
            "Gamın 7. notası eve sadece yarım ses uzaktadır ve kulağı neredeyse mıknatıs gibi "
            "eve çeker. Aşağıda önce gamı 7. notada kesiyoruz (A), sonra eve tamamlıyoruz (B). "
            "A'nın sonunda “bitmedi” hissini, B'de rahatlamayı fark et.",
        sound: ScaleSound(notes: [48, 50, 52, 53, 55, 57, 59]),
        soundLabel: "7. notada kalan gam (bitmemiş)",
        compareSound: ScaleSound(notes: [48, 50, 52, 53, 55, 57, 59, 60]),
        compareLabel: "Eve varan gam (tamamlanmış)",
        terms: {
          "Yönlendirici ses": "Gamın 7. notası; eve yarım ses uzakta durup oraya çekilir (leading tone).",
        },
        keyIdea: "7. derece eve yarım ses uzaktadır ve oraya çözülmek ister.",
      ),
      LessonPoint(
        heading: "Do-Re-Mi ile düşün: notaların kişiliği",
        body:
            "Solfej, gamın notalarını tona göre adlandırır: ev her zaman “Do”dur. Her notanın "
            "bir kişiliği vardır: Do ve Sol sağlam ve dengelidir; Si, Do'ya yukarı çekilir; "
            "Fa, Mi'ye aşağı iner. Bu iki çekimi duymak, bir şarkının evini bulmanın en "
            "kestirme yoludur.",
        sound: ScaleSound(notes: [48, 52, 55, 60, 59, 60], stepDurationMs: 420),
        soundLabel: "Evi kur, sonra Si → Do",
        compareSound: ScaleSound(notes: [48, 52, 55, 60, 53, 52], stepDurationMs: 420),
        compareLabel: "Evi kur, sonra Fa → Mi",
        terms: {
          "Solfej": "Notaları tona göre Do-Re-Mi-Fa-Sol-La-Si diye adlandırma; ev her zaman Do.",
        },
        keyIdea: "Si yukarı Do'ya, Fa aşağı Mi'ye çekilir — bunlar tonun mıknatıslarıdır.",
      ),
      LessonPoint(
        heading: "Yeni beceri: alçalan aralıklar",
        body:
            "Bu haftadan itibaren aralıkların bir kısmı yukarıdan aşağı çalınacak. Kaynaklar, "
            "yükselen aralıkları tanıdıktan hemen sonra alçalanlara geçmeyi önerir, çünkü "
            "aşağı inen bir aralık kulakta bambaşka bir “şekil”dir ve ayrı çapalar ister. "
            "Soruda “↓” işaretini görürsün.",
        sound: IntervalSound(rootMidi: 45, interval: EarIntervalType.minor3, descending: true),
        soundLabel: "Küçük 3'lü ↓ (Küçük Kurbağa)",
        compareSound: IntervalSound(rootMidi: 45, interval: EarIntervalType.major3, descending: true),
        compareLabel: "Büyük 3'lü ↓ (ding-dong)",
        examples: [
          "Küçük 3'lü ↓: “Küçük Kurbağa” (“Kü – çük”), birine uzaktan seslenmek (“Ah – met!”)",
          "Büyük 3'lü ↓: Beethoven 5. Senfoni (“ta-ta-ta-TAM”), klasik “ding-dong” kapı zili",
          "Tam 5'li ↓: “Çakmaktaşlar” (The Flintstones) teması; “Yaşasın Okulumuz” açılışının tersi",
        ],
        keyIdea: "Aşağı inen aralık ayrı bir beceridir; onun için ayrı çapa şarkılar edin.",
      ),
      LessonPoint(
        heading: "Harmonik ritim: akorlar ne zaman değişir?",
        body:
            "Harmonik ritim, akorların değişme hızıdır. Çoğu pop ve rock şarkısında bir akor "
            "4 vuruş (1 tam ölçü) sürer: 1-2-3-4 boyunca aynı akor, yeni “1”de bir sonraki. "
            "Aşağıdaki döngüyü içinden 1-2-3-4 sayarak dinle.",
        sound: HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [43, 47, 50, 55],
            [45, 48, 52, 57],
            [41, 45, 48, 53],
          ],
          beatsPerChord: 4,
        ),
        soundLabel: "4 vuruşta bir değişim (C-G-Am-F)",
        terms: {
          "Harmonik ritim": "Akorların değişme hızı ve zamanlaması.",
        },
        keyIdea: "En yaygın düzen: her ölçünün başında, yani her “1”de yeni akor.",
      ),
      LessonPoint(
        heading: "Hızlı geçiş: 2 vuruşta bir",
        body:
            "Bazı şarkılarda, özellikle nakarata yaklaşırken, akorlar iki kat hızlanır: 1-2 "
            "bir akor, 3-4 diğeri. Aynı dört akoru iki hızda karşılaştır.",
        sound: HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [43, 47, 50, 55],
            [45, 48, 52, 57],
            [41, 45, 48, 53],
          ],
          beatsPerChord: 2,
        ),
        soundLabel: "2 vuruşta bir (hızlı)",
        compareSound: HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [43, 47, 50, 55],
            [45, 48, 52, 57],
            [41, 45, 48, 53],
          ],
          beatsPerChord: 4,
        ),
        compareLabel: "4 vuruşta bir (geniş)",
        keyIdea: "Hem “1”de hem “3”te değişim varsa ritim 2 vuruşluktur.",
      ),
      LessonPoint(
        heading: "Yavaş şarkılar: 8 vuruşta bir",
        body:
            "Ballad ve yavaş şarkılarda bir akor iki tam ölçü (8 vuruş) boyunca sürebilir: bir "
            "“1”de değişir, sonraki “1”de değişmez, ondan sonrakinde değişir. Alıştırmalarda bu "
            "üç hız (2, 4, 8) karışık gelecek; tempo ve akorlar her soruda değişeceği için "
            "sesin uzunluğuna değil, değişimlerin sıklığına odaklan.",
        sound: HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [43, 47, 50, 55],
          ],
          beatsPerChord: 8,
        ),
        soundLabel: "8 vuruşta bir (çok geniş)",
        compareSound: HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [43, 47, 50, 55],
            [45, 48, 52, 57],
            [41, 45, 48, 53],
          ],
          beatsPerChord: 4,
        ),
        compareLabel: "4 vuruşta bir (geniş)",
        keyIdea: "Her “1”i say: hepsinde değişim = 4, birinde var birinde yok = 8.",
      ),
      LessonPoint(
        heading: "Değişimi yakalamanın 3 yolu",
        body:
            "Akor değişimleri neredeyse her zaman güçlü vuruşlara (1 ve 3) düşer. Bas gitar "
            "en güvenilir işaretçindir: bas notası değiştiğinde akor da büyük ihtimalle "
            "değişmiştir. İlk denemelerde kaçırman çok normal; zamana oturma becerisi bir kas "
            "gibi gelişir.",
        examples: [
          "Ayağınla tempoyu tut, sadece “1”leri say",
          "Basa odaklan: bas notası değişti mi?",
          "Kısa bir bölümü tekrar tekrar dinle ve değişim anında elini vur",
        ],
        tryThis:
            "Bir şarkıdan 4 ölçülük kısa bir bölüm seç. Her akor değişiminde masaya vur ve "
            "vuruşların “1”e mi yoksa “1” ve “3”e mi düştüğünü say.",
      ),
      LessonPoint(
        heading: "Bu hafta nasıl çalışacaksın",
        body:
            "Bu hafta aralık sorularına (bazıları artık alçalan) ek olarak Harmonik Ritim "
            "sorularında akorların 2, 4 ya da 8 vuruşta bir mi değiştiğini bulacaksın. "
            "Kulaklık takmak, özellikle basın ve vuruşun daha net duyulmasını sağlar.",
        keyIdea: "Alçalan aralıklarda zorlanırsan ders kartındaki ↓ örneklerini yeniden dinle.",
      ),
    ],
    exercises: [EarExerciseKind.harmonicRhythm, EarExerciseKind.intervalBlind],
    gate: MasteryGate(accuracyThreshold: 0.80, minQuestions: 20, minDaysActive: 4),
    bossTitle: "Hafta 2 Boss: Harmonik Ritim Sayaç Testi",
  ),
  // ---------------------------------------------------------------- HAFTA 3
  EarWeek(
    weekNumber: 3,
    title: "Gam Dereceleri & Tam 4'lü",
    subtitle: "Roma rakamları, fonksiyonel dinleme ve yeni aralık: tam 4'lü",
    theoryBrief:
        "Notayı adıyla değil, tondaki göreviyle düşün: 1, 3 ve 5 ev hissi verir; 4 ve 7 hareket ister. Tam 4'lü “soru”, tam 5'li “cevap” gibidir.",
    lesson: [
      LessonPoint(
        heading: "Dereceler: harf yerine numara",
        body:
            "Bir tondaki her nota, eve göre bir numara alır: 1, 2, 3, 4, 5, 6, 7. Notayı “Re” "
            "diye değil “bu tonun 2. derecesi” diye düşünmek, aynı kalıbı her tonda tanımanı "
            "sağlar. Akorlar Roma rakamıyla yazılır: I, ii, iii, IV, V, vi, vii°.",
        sound: ChordSound(rootMidi: 48, quality: EarChordQuality.major),
        soundLabel: "I. derece akoru (ev)",
        terms: {
          "Derece": "Bir notanın tondaki sıra numarası (1-7).",
          "Roma rakamı": "Akorları dereceyle yazma: büyük harf majör (I), küçük harf minör (ii).",
          "Azalmış akor (°)": "Küçük 3'lü ve küçültülmüş 5'liden oluşan, gergin akor (vii°).",
        },
        keyIdea: "Kalıp tondan tona aynı kalır; değişen sadece başlangıç notasıdır.",
      ),
      LessonPoint(
        heading: "Fonksiyonel dinleme: önce evi kur",
        body:
            "Aralıkları tek başına ölçmek gerekli ama yeterli değil. Uzmanlar, notaları tona "
            "göre “görevleriyle” duymayı daha pratik buluyor: önce ev kurulur, sonra bir nota "
            "çalınır ve o notanın eve nasıl çözüldüğü dinlenir. Aşağıda önce Do majör akorunun "
            "notalarıyla ev kuruluyor; A'da 7. derece (Si) eve çıkıyor, B'de 4. derece (Fa) "
            "3'e iniyor.",
        sound: ScaleSound(notes: [48, 52, 55, 60, 59, 60], stepDurationMs: 420),
        soundLabel: "Ev + 7. derece → eve",
        compareSound: ScaleSound(notes: [48, 52, 55, 60, 53, 52], stepDurationMs: 420),
        compareLabel: "Ev + 4. derece → 3'e",
        terms: {
          "Fonksiyonel dinleme": "Bir notayı tondaki görevine (eve göre konumuna) bakarak tanımak.",
        },
        examples: [
          "Alain Benbassat'ın yöntemi (Functional Ear Trainer uygulaması): önce bir kadans çalınır, sonra tek bir nota; öğrenci o notanın eve nasıl çözüldüğünü dinleyerek derecesini bulur",
        ],
        keyIdea: "Bir notayı tek başına değil, eve göre konumuyla tanı.",
      ),
      LessonPoint(
        heading: "Derecelerin isimleri",
        body:
            "Her derecenin klasik müzikten gelen bir ismi var. En sık duyacakların: Tonik (1, "
            "ev), Subdominant (4, hareket) ve Dominant (5, gerilim). Aşağıda dominant (V) ve "
            "tonik (I) akorlarını karşılaştır: biri “bekliyor”, diğeri “oturuyor”.",
        sound: ChordSound(rootMidi: 55, quality: EarChordQuality.major),
        soundLabel: "V (dominant, gerilim)",
        compareSound: ChordSound(rootMidi: 48, quality: EarChordQuality.major),
        compareLabel: "I (tonik, ev)",
        terms: {
          "Dominant": "5. derece ve üzerine kurulan akor; gerilim yaratır, eve dönmek ister.",
          "Subdominant": "4. derece; evden uzaklaşmayı başlatan, hareket hissi veren akor.",
        },
        keyIdea: "Tonik = ev, subdominant = yola çıkış, dominant = eve dönme isteği.",
      ),
      LessonPoint(
        heading: "I → V: bitmemiş cümle",
        body:
            "Evden dominanta giden bir hareket cümleyi bitirmez; kulak bir devam bekler. "
            "Aşağıda I → V hareketini, ardından I → IV hareketini dinle. İkisi de evden çıkar "
            "ama V gergin bir soru gibi asılı kalır, IV ise rahat bir açılış gibi duyulur.",
        sound: CadenceSound(rootMidi: 48, cadence: EarCadenceType.I_V),
        soundLabel: "I → V (askıda)",
        compareSound: CadenceSound(rootMidi: 48, cadence: EarCadenceType.I_IV),
        compareLabel: "I → IV (açılış)",
        keyIdea: "V'de biten bir cümle “peki sonra?” diye sorar.",
      ),
      LessonPoint(
        heading: "Üç aile: tonik, subdominant, dominant",
        body:
            "7 akor aslında 3 aileye ayrılır. Bir şarkıyı dinlerken tek tek akorları değil bu "
            "aileleri takip etmeye çalış. Tonik → subdominant → dominant → tonik, müzikte en "
            "doğal yolculuktur (I → IV → V → I). 8. haftada bu ailelerin pop müziğin büyük "
            "kısmını nasıl açıkladığını göreceksin.",
        examples: [
          "Tonik ailesi (I, iii, vi): evdeyim, durağan",
          "Subdominant ailesi (IV, ii): yola çıkıyorum",
          "Dominant ailesi (V, vii°): eve dönmem lazım, gergin",
        ],
        terms: {
          "Fonksiyon": "Bir akorun tondaki rolü: ev, hareket ya da gerilim.",
        },
        keyIdea: "Her akor üç rolden birini oynar: ev, yola çıkış ya da dönüş isteği.",
      ),
      LessonPoint(
        heading: "Yeni aralık: tam 4'lü",
        body:
            "Tam 4'lü (5 yarım ses) açık ve “yukarı çağıran” bir his verir; ne majör ne minör "
            "bir renk taşır. En çok tam 5'li ile karışır, çünkü ikisi birbirinin ters "
            "çevrilmişidir. A ve B'yi karşılaştır: 4'lü daha dar ve “soru gibi”, 5'li daha "
            "geniş ve “cevap gibi” duyulur.",
        sound: IntervalSound(rootMidi: 45, interval: EarIntervalType.perfect4),
        soundLabel: "Tam 4'lü (dar, soru)",
        compareSound: IntervalSound(rootMidi: 45, interval: EarIntervalType.perfect5),
        compareLabel: "Tam 5'li (geniş, cevap)",
        examples: [
          "↑ İstiklal Marşı açılışı (“Kork – ma”), Düğün Marşı, Harry Potter ana teması",
          "↓ İstiklal Marşı açılışının tersi: gitarda 5. tel boş La'dan 6. tel boş Mi'ye iniş",
          "Gitarda: 5. tel boş La ile 4. tel boş Re arası bir tam 4'lüdür",
        ],
        keyIdea: "4'lü soru gibi açılır, 5'li cevap gibi oturur.",
        tryThis:
            "4'lü → 5'li → 4'lü dizisini mırıldan. Bir aralık duyduğunda bu dizinin hangi "
            "kısmına benzediğine bak.",
      ),
      LessonPoint(
        heading: "Gitarist taktiği: kalıbı taşı",
        body:
            "Bir riffi “Do'dan Mi'ye” değil “1. dereceden 3. dereceye” diye düşünürsen, onu "
            "her tonda anında çalabilirsin: parmak şekli aynı kalır, sadece başlangıç perdesi "
            "kayar. Kulaktan riff çıkarırken önce kalıbı yakala, tonu sonra bul.",
        tryThis:
            "5. telin 3. perdesinden başlayan basit bir melodi çal, sonra aynı parmak "
            "şeklini 5. perdeden başlatarak tekrarla. Melodi aynı, sadece ton değişti.",
      ),
      LessonPoint(
        heading: "Bu hafta nasıl çalışacaksın",
        body:
            "Bu hafta iki tür soru var. Aralık sorularında artık beş aralık var: küçük 3'lü, "
            "büyük 3'lü, tam 4'lü, tam 5'li ve oktav. Yeni Derece Tanıma sorularında önce ev "
            "kurulur (Do-Mi-Sol-Do), ardından tek bir nota çalar; o notanın kaçıncı derece "
            "olduğunu bulursun (1, 3, 4, 5 ya da 7). Cevapladıktan sonra “Eve çözülüşünü dinle” "
            "ile notanın eve nasıl yürüdüğünü duy.",
        keyIdea: "Derecede notayı ölçme, hisset: oturmuş mu (1, 3, 5), aşağı mı (4), yukarı mı (7) gitmek istiyor?",
      ),
    ],
    exercises: [EarExerciseKind.intervalBlind, EarExerciseKind.scaleDegree],
    gate: MasteryGate(accuracyThreshold: 0.80, minQuestions: 25, minDaysActive: 5),
    bossTitle: "Hafta 3 Boss: Derece Radarı",
  ),
  // ---------------------------------------------------------------- HAFTA 4
  EarWeek(
    weekNumber: 4,
    title: "Triadlar, Akor Kalitesi & 2'liler",
    subtitle: "Majör, minör, sus2, power chord ve yeni aralıklar: küçük ve büyük 2'li",
    theoryBrief:
        "Akorun rengini 3'lü belirler: büyük 3'lü majör (güneşli), küçük 3'lü minör (gölgeli). 3'lü yoksa (sus2, power) akor asılı ya da nötr kalır. 2'liler ise melodinin adımlarıdır.",
    lesson: [
      LessonPoint(
        heading: "Triad: üç notalı akor",
        body:
            "Triad, bir akorun en yalın hâlidir: kök, 3'lü ve 5'li. Majör ile minör arasındaki "
            "tek fark 3'lünün yarım ses yukarıda ya da aşağıda olmasıdır; kök ve 5'li aynı "
            "kalır. Bu küçük fark kulakta çok büyük bir duygu farkı yaratır.",
        sound: ChordSound(rootMidi: 45, quality: EarChordQuality.major),
        soundLabel: "La majör (güneşli)",
        compareSound: ChordSound(rootMidi: 45, quality: EarChordQuality.minor),
        compareLabel: "La minör (gölgeli)",
        terms: {
          "Triad": "Kök, 3'lü ve 5'liden oluşan üç notalı akor.",
          "Akor kalitesi": "Akorun türü ve rengi: majör, minör, sus2 vb.",
          "♭ (bemol)": "Yarım ses pesleştirme. ♭3 = küçük 3'lü.",
        },
        keyIdea: "Majör ile minörü ayıran tek nota 3'lüdür.",
      ),
      LessonPoint(
        heading: "Akorun içini duy: ortadaki notayı mırıldan",
        body:
            "Akorlar birlikte çalındığında notaları ayırmak zor olabilir. Arpej (notaları tek "
            "tek çalmak) akorun içini açar. Kaynakların önerisi: her duyduğun akorun 3'lüsünü "
            "mırıldan. Alıştırmada emin olamazsan “Arpej çal” düğmesine bas ve ortadaki notaya "
            "odaklan.",
        sound: ChordSound(rootMidi: 45, quality: EarChordQuality.major, arpeggio: true),
        soundLabel: "Majör arpej",
        compareSound: ChordSound(rootMidi: 45, quality: EarChordQuality.minor, arpeggio: true),
        compareLabel: "Minör arpej",
        examples: [
          "Minör arpejin sesi: “Hatırla Sevgili”nin “Ha-tır-la” kelimesi (La-Do-Mi)",
        ],
        keyIdea: "Ortadaki nota aydınlıksa majör, gölgeliyse minör.",
        tryThis:
            "A ve B'yi dinlerken ikinci notayı yüksek sesle mırıldan. Hangisinin “gülümsediğini” "
            "söyle.",
      ),
      LessonPoint(
        heading: "Sus2: karar vermemiş akor",
        body:
            "Sus2'de 3'lü yoktur; yerine 2. derece gelir (1-2-5). Rengi veren nota eksik "
            "olduğu için akor ne mutlu ne hüzünlüdür: asılı, açık, çan gibi bir tını duyarsın. "
            "Akustik gitar girişlerinde çok sık kullanılır.",
        sound: ChordSound(rootMidi: 45, quality: EarChordQuality.sus2),
        soundLabel: "Sus2 (asılı, çan gibi)",
        compareSound: ChordSound(rootMidi: 45, quality: EarChordQuality.major),
        compareLabel: "Majör (net, güneşli)",
        terms: {
          "Sus (suspended)": "“Asılı”: 3'lünün yerine başka bir derece konmuş akor.",
        },
        examples: [
          "Gitarda: açık Dsus2 (xx0230) ve Asus2 (x02200)",
        ],
        keyIdea: "Akor bir duygu vermiyor ama parlak ve hareketliyse sus2 olabilir.",
      ),
      LessonPoint(
        heading: "Power chord: sadece kök ve 5'li",
        body:
            "Power chord yalnızca kök ve 5'liden oluşur (1-5). Ne majör ne minördür; rengi "
            "nötrdür. Bu yüzden distorsiyonlu gitarda “kirlenmeden” temiz kalır ve rock "
            "rifflerinin temelidir. Sus2'den farkı: sus2'de araya bir renk notası girer, power "
            "chord ise tamamen çıplaktır.",
        sound: ChordSound(rootMidi: 45, quality: EarChordQuality.power),
        soundLabel: "Power chord (çıplak, boş)",
        compareSound: ChordSound(rootMidi: 45, quality: EarChordQuality.sus2),
        compareLabel: "Sus2 (parlak, hafif sürtünme)",
        examples: [
          "Gitarda: 6. tel boş + 5. tel 2. perde = E5",
          "Rock ve metal rifflerinin büyük kısmı power chord üzerine kuruludur",
        ],
        keyIdea: "Boş, sert ve renksiz bir akor duyuyorsan power chord.",
      ),
      LessonPoint(
        heading: "Yeni aralıklar: 2'liler, yani melodinin adımları",
        body:
            "Sus2 akorunun içinde kök ile 2. derece arasında yeni bir aralık var: büyük 2'li. "
            "2'liler gamda yan yana duran iki notadır; melodilerin büyük kısmı bu küçük "
            "adımlarla ilerler. Şimdiye kadarki aralıklar (3'lü, 4'lü, 5'li, oktav) birer "
            "sıçramaydı; 2'liler ise adımdır. Akorların temelini kurduğumuz için artık "
            "melodiye geçmenin zamanı.",
        sound: ScaleSound(notes: [48, 50, 48, 52], stepDurationMs: 520),
        soundLabel: "Önce adım (Do → Re), sonra sıçrama (Do → Mi)",
        terms: {
          "Adım": "Gamda yan yana iki nota arasındaki hareket (2'li).",
          "Sıçrama": "Arada en az bir notayı atlayan hareket (3'lü ve daha geniş).",
        },
        keyIdea: "2'li bir adımdır; 3'lü ve daha genişi bir sıçramadır.",
        tryThis:
            "Gitarda tek telde 2 perde ilerle (büyük 2'li), sonra 1 perde ilerle (küçük 2'li). "
            "İkisini de mırıldan.",
      ),
      LessonPoint(
        heading: "Küçük 2'li mi, büyük 2'li mi?",
        body:
            "Küçük 2'li (1 yarım ses) en dar aralıktır. İki nota birbirine çok yakın olduğu "
            "için gergin, sürtünen bir his verir; birlikte çalındığında belirgin bir cızırtı "
            "duyarsın. Büyük 2'li (2 yarım ses) ise gamda sıradan, rahat bir adımdır. A ve B'yi "
            "karşılaştır.",
        sound: IntervalSound(rootMidi: 48, interval: EarIntervalType.major2),
        soundLabel: "Büyük 2'li (rahat adım)",
        compareSound: IntervalSound(rootMidi: 48, interval: EarIntervalType.minor2),
        compareLabel: "Küçük 2'li (gergin, sürtünen)",
        examples: [
          "Büyük 2'li ↑: “İyi ki Doğdun”un açılışı (“İ-yi – ki”), “Frère Jacques”",
          "Büyük 2'li ↓: “Mary Had a Little Lamb” (“Ma – ry”)",
          "Küçük 2'li ↑: “Jaws” filminin köpekbalığı teması, “Pembe Panter” teması",
          "Küçük 2'li ↓: Beethoven “Für Elise” açılışı",
        ],
        keyIdea: "Küçük 2'li gerilim ve tehlike (Jaws), büyük 2'li sıradan bir adım (İyi ki Doğdun).",
      ),
      LessonPoint(
        heading: "Neden majör aydınlık, minör hüzünlü?",
        body:
            "Kesin bir bilimsel cevap yok. En çok kabul gören açıklama iki etkenin birlikte "
            "çalıştığıdır: büyük 3'lünün frekans oranı (yaklaşık 5:4) küçük 3'lününkinden "
            "(yaklaşık 6:5) biraz daha basittir, ve Batı müziğinde yüzyıllardır majör = mutlu, "
            "minör = hüzünlü kullanımı kültürel bir alışkanlık yaratmıştır.",
        keyIdea: "Sebebi ne olursa olsun, bu ayrım kulağının en güvenilir araçlarından biridir.",
      ),
      LessonPoint(
        heading: "Gitarist taktiği: triadı farklı tellerde çal",
        body:
            "Aynı triadı farklı tel gruplarında çal: 1-2-3. teller, 2-3-4. teller, 3-4-5. "
            "teller. Notalar aynı olsa da tını değişir. Amaç, kulağının “majör mü minör mü” "
            "kararını akorun nerede çalındığından bağımsız verebilmesi.",
        tryThis:
            "Bildiğin bir majör akoru iki farklı pozisyonda çal, sonra minörünü aynı iki "
            "pozisyonda çal. Her pozisyonda farkın aynı kaldığını duy.",
      ),
      LessonPoint(
        heading: "Akustik gitarda üst tel “drone” kalıbı",
        body:
            "“Wonderwall” gibi bazı akustik şarkılarda üstteki iki tel sabit tutulur, akorlar "
            "değişirken bu notalar sürekli çınlar. Bu yüzden akorlar birbirine kolayca geçer. "
            "Üstteki notalar hep aynı kalırken sadece bas hareket ediyorsa muhtemelen bu "
            "kalıptasın.",
        terms: {
          "Drone": "Akorlar değişirken sürekli çalmaya devam eden sabit nota.",
        },
        examples: [
          "Oasis “Wonderwall”: capo 2. perdede, üst iki tel 3. perdede sabit (10. haftada capo'ya dönüyoruz)",
        ],
      ),
      LessonPoint(
        heading: "Bu hafta nasıl çalışacaksın",
        body:
            "Bu hafta iki tür soru var. Akor kalitesi sorularında dört seçenek var: zorlanırsan "
            "önce “3'lü var mı?” diye sor; varsa majör ya da minör, yoksa sus2 ya da power. "
            "Aralık sorularına ise 2'liler katıldı; artık yedi seçenek var. Bir aralık "
            "duyduğunda önce “adım mı, sıçrama mı?” diye sor.",
        keyIdea: "Akorda: 3'lü var mı? Aralıkta: adım mı, sıçrama mı?",
      ),
    ],
    exercises: [EarExerciseKind.chordQuality, EarExerciseKind.intervalBlind],
    gate: MasteryGate(accuracyThreshold: 0.80, minQuestions: 30, minDaysActive: 5),
    bossTitle: "Hafta 4 Boss: Kulaktan Kör Akor Kalitesi",
  ),
  // ---------------------------------------------------------------- HAFTA 5
  EarWeek(
    weekNumber: 5,
    title: "Konsolidasyon 1: İlk Şarkı Çıkarma",
    subtitle: "Yeni teori yok: 1-4. haftayı birleştir ve ilk şarkını kulaktan çıkar",
    theoryBrief:
        "Şarkıyı yavaşlat, 2 ölçülük bir bölümü döngüye al. Önce 1. vuruştaki bası, sonra akorun majör mü minör mü olduğunu bul.",
    lesson: [
      LessonPoint(
        heading: "Yeni teori yok: birleştirme zamanı",
        body:
            "İlk dört haftada aralıkları, harmonik ritmi, gam derecelerini ve akor kalitesini "
            "ayrı ayrı öğrendin. Bu hafta bunları tek bir beceride birleştiriyorsun: gerçek bir "
            "şarkıdan akor dizisini kulaktan çıkarmak. Bu, teorinin işe yarayıp yaramadığını "
            "göreceğin ilk gerçek test.",
        examples: [
          "Aralıklar: küçük/büyük 2'li, küçük/büyük 3'lü, tam 4'lü, tam 5'li, oktav (↑ ve ↓)",
          "Harmonik ritim: 2 vuruş mu, 4 vuruş mu?",
          "Dereceler: ev (I), hareket (IV), gerilim (V)",
          "Akor kalitesi: majör, minör, sus2, power",
        ],
        keyIdea: "Bu hafta ölçülen şey, ayrı ayrı bildiklerini aynı anda kullanabilmen.",
      ),
      LessonPoint(
        heading: "Karışık sorular neden zor (ve neden iyi)?",
        body:
            "Bu haftanın soruları farklı türleri rastgele karıştırır. Gerçek bir şarkıda hangi "
            "beceriyi kullanacağını önceden bilmezsin; kulağın anında karar vermeyi öğrenmeli. "
            "Aralık eğitimi üzerine araştırmalar ilginç bir tablo çiziyor: aynı türü art arda "
            "çalışmak başta doğruluğu hızlı artırır, türleri karıştırmak ise uzun vadede daha "
            "kalıcı ve esnek bir öğrenme sağlar. İlk dört hafta birinciydi, bu hafta ikinci.",
        terms: {
          "Bloklu pratik": "Aynı türü art arda çalışmak (örneğin 10 aralık sorusu üst üste).",
          "Karışık pratik": "Farklı türleri karışık sırayla çalışmak (interleaving).",
        },
        keyIdea: "Karışık sorular zor gelir ama tam da bu zorluk kalıcılığı artırır.",
      ),
      LessonPoint(
        heading: "Transkripsiyon rutini: 5 adım",
        body:
            "Kulaktan şarkı çıkarmak rastgele denemekle değil, sabit bir sırayla hızlanır. "
            "Bir sonraki akora geçmeden önce mevcut olanı mutlaka doğrula: yanlış bir akorla "
            "devam etmek, sonraki her şeyi de kaydırır.",
        terms: {
          "Transkripsiyon": "Duyduğun müziği nota ya da akor olarak yazıya dökmek.",
          "Döngü (loop)": "Kısa bir bölümü tekrar tekrar çalmak.",
        },
        examples: [
          "1) Şarkıyı yavaşlat (0.5x – 0.75x; çoğu oynatıcıda hız ayarı var)",
          "2) 2 ölçülük kısa bir bölümü döngüye al",
          "3) 1. vuruştaki bası mırıldan ve gitarda bul",
          "4) Üstteki akor majör mü, minör mü?",
          "5) Akoru çal, kayıtla aynı anda dinle: tutuyor mu?",
        ],
        keyIdea: "Bası bul → rengi bul → kayıtla birlikte çalarak doğrula.",
        tryThis: "İlk denemende bir şarkının sadece ilk 30 saniyesini hedefle.",
      ),
      LessonPoint(
        heading: "İlk şarkı için iyi bir seçim",
        body:
            "İlk transkripsiyon için az akorlu, temposu orta ve akorları net duyulan bir şarkı "
            "seç. The Beatles'ın “Let It Be” şarkısı bunun için klasik bir örnektir: kıtası Do "
            "majörde C-G-Am-F akorları üzerinde döner. Bu dört akoru bildiğin hâlde kulakla "
            "bulmaya çalışmak, cevabı kontrol edebileceğin güvenli bir başlangıçtır.",
        examples: [
          "“Let It Be” (The Beatles): C – G – Am – F",
          "Basit, tanıdık bir Türkçe şarkı da seçebilirsin; önemli olan akorların az ve net olması",
        ],
        sound: CadenceSound(rootMidi: 48, cadence: EarCadenceType.I_V_vi_IV),
        soundLabel: "C – G – Am – F döngüsü",
        tryThis:
            "Önce cevabı bilmeden dene: her akorun basını ve rengini yaz. Sonra internetten "
            "akorlara bakıp kendini kontrol et.",
      ),
      LessonPoint(
        heading: "Vaka analizi: “Şımarık” neden 17 dilde söylendi?",
        body:
            "Tarkan'ın 1999'da çıkardığı “Şımarık” Fransa, Hollanda, Norveç, İsveç ve "
            "İsviçre'de ilk 3'e girdi, Valonya'da (Belçika) 1 numara oldu ve 17'den fazla dile "
            "uyarlandı; Holly Valance'ın 2002'deki İngilizce versiyonu “Kiss Kiss” Avustralya "
            "ve Birleşik Krallık listelerinde zirveye çıktı. Sırrı karmaşık bir teori değil, "
            "akılda kalıcı bir kanca: güçlü bir melodi dil bariyerini aşabiliyor.",
        terms: {
          "Kanca (hook)": "Şarkının akılda kalan, tekrar eden kısa parçası.",
        },
        tryThis:
            "“Şımarık”ın nakaratını dinle: 1-2-3-4 sayarak 1. vuruş basını yakala ve akorun "
            "majör mü minör mü olduğunu not et.",
      ),
    ],
    exercises: [EarExerciseKind.interleaved],
    gate: MasteryGate(accuracyThreshold: 0.80, minQuestions: 30, minDaysActive: 5),
    isConsolidation: true,
    bossTitle: "Konsolidasyon Boss: Karışık Aralık & Kalite İmtihanı",
  ),
  // ---------------------------------------------------------------- HAFTA 6
  EarWeek(
    weekNumber: 6,
    title: "İlgili Minör & Majör V Tuzağı",
    subtitle: "Harmonik minör: La minörde Em yerine E / E7 gerilimi",
    theoryBrief:
        "Harmonik minörde 7. derece yarım ses tizleştirilir (La minörde Sol → Sol#). Bu nota V akorunu minörden majöre çevirir ve eve güçlü bir çekim yaratır.",
    lesson: [
      LessonPoint(
        heading: "İlgili minör: aynı notalar, farklı ev",
        body:
            "Her majör tonun bir ilgili minörü vardır: ikisi aynı 7 notayı kullanır, sadece "
            "evleri farklıdır. Do majör ile La minör aynı notaları paylaşır (diyez ya da bemol "
            "yok). İlgili minörü bulmak kolay: majör tonun 6. derecesi.",
        sound: ScaleSound(notes: [48, 50, 52, 53, 55, 57, 59, 60]),
        soundLabel: "Do majör (ev: Do)",
        compareSound: ScaleSound(notes: [45, 47, 48, 50, 52, 53, 55, 57]),
        compareLabel: "La minör (aynı notalar, ev: La)",
        terms: {
          "İlgili minör": "Bir majör tonla aynı notaları paylaşan, 6. dereceden başlayan minör ton.",
        },
        keyIdea: "Notalar aynı kalır; değişen, hangi notanın “ev” hissettirdiğidir.",
      ),
      LessonPoint(
        heading: "Harmonik minör: tek bir nota değişiyor",
        body:
            "Doğal minörde 7. derece eve tam ses uzaktadır ve eve güçlü bir çekim yaratmaz. "
            "Harmonik minörde bu nota yarım ses tizleştirilir (La minörde Sol → Sol#). Artık "
            "eve yarım ses uzaktadır ve tıpkı majördeki gibi bir yönlendirici ses olur. A ve "
            "B'nin son iki notasına odaklan.",
        sound: ScaleSound(notes: [45, 47, 48, 50, 52, 53, 55, 57]),
        soundLabel: "Doğal minör (Sol → La)",
        compareSound: ScaleSound(notes: [45, 47, 48, 50, 52, 53, 56, 57]),
        compareLabel: "Harmonik minör (Sol# → La)",
        terms: {
          "Doğal minör": "İlgili majörle aynı notaları kullanan minör gam.",
          "Harmonik minör": "7. derecesi yarım ses tizleştirilmiş minör gam.",
          "♯ (diyez)": "Yarım ses tizleştirme.",
        },
        keyIdea: "Harmonik minör = doğal minör + tizleşmiş 7. derece.",
      ),
      LessonPoint(
        heading: "Majör V tuzağı: neden Em değil E?",
        body:
            "Doğal minörde 5. derece akoru minördür (La minörde Em). Ama gerçek şarkılarda "
            "çoğu zaman onun yerine majör E ya da E7 duyarsın. Sebebi o tizleşen Sol#: E "
            "akorunun 3'lüsüdür ve akoru minörden (Mi-Sol-Si) majöre (Mi-Sol#-Si) çevirir. "
            "Minör bir şarkıda aniden parlak bir akor duyarsan, büyük ihtimalle budur.",
        sound: ChordSound(rootMidi: 52, quality: EarChordQuality.minor),
        soundLabel: "Em (doğal minörün v'si)",
        compareSound: ChordSound(rootMidi: 52, quality: EarChordQuality.major),
        compareLabel: "E (harmonik minörün V'si)",
        keyIdea: "Minör şarkıda “beklenmedik parlak akor” = büyük ihtimalle majör V.",
      ),
      LessonPoint(
        heading: "V7 → i: güçlü dönüş",
        body:
            "Majör V'nin (özellikle E7'nin) içindeki Sol#, kulağı La'ya çeker. Bu hareket "
            "gerilim kurup eve güçlü bir şekilde çözülür. Flamenko, blues, Anadolu ve Balkan "
            "müziğinde sık duyulur.",
        sound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.V7_i),
        soundLabel: "E7 → Am",
        terms: {
          "Çözülme": "Gergin bir akorun ya da notanın daha durağan olana geçmesi.",
        },
        keyIdea: "E7 gerilir, Am rahatlar: minörün en güçlü kapanışı budur.",
      ),
      LessonPoint(
        heading: "Endülüs kadansı: dünyaca ünlü bir örnek",
        body:
            "La minörde Am – G – F – E dizisi “Endülüs kadansı” olarak bilinir: dört akor "
            "basamak basamak iner ve majör E ile biter. Bu son akor tam olarak bu haftanın "
            "tuzağıdır: minörde majör V. Flamenkonun temeli olan bu dizi pop ve rock'ta da çok "
            "sık kullanılır.",
        terms: {
          "Endülüs kadansı": "Minörde i – ♭VII – ♭VI – V dizisi (Am – G – F – E).",
        },
        examples: [
          "Ray Charles “Hit the Road Jack”: Am – G – F – E",
          "Dire Straits “Sultans of Swing”: aynı iniş Re minörde (Dm – C – B♭ – A)",
        ],
        keyIdea: "Am – G – F – E'nin sonundaki E majördür: harmonik minörün izi.",
        tryThis:
            "Gitarda Am – G – F – E'yi yavaşça çal. Son akordaki Sol#'ın kulağını Am'ye nasıl "
            "geri çektiğini dinle.",
      ),
      LessonPoint(
        heading: "Aynı akorlar, iki kimlik",
        body:
            "Bir tonun akorları aynı 7 notayı paylaştığı için, aynı dizi hangi akorda "
            "dinlendiğine göre majör ya da minör hissettirebilir. Evi bulmanın yolu: dizinin "
            "ilk akoruna değil, gerilimin bittiği, kulağının rahatladığı akora bakmak.",
        keyIdea: "Ev, dizinin başladığı değil, rahatladığın akordur.",
      ),
      LessonPoint(
        heading: "Gitarist taktiği: harmonik minörü hızlı bul",
        body:
            "Bildiğin doğal minör gam şeklinden harmonik minöre geçmek tek bir değişiklik "
            "ister: 7. dereceyi bir perde ileri kaydır. Geri kalan her şey aynı kalır.",
        tryThis:
            "5. telde boş La'dan başlayan La minör gamı çal. 7. notaya (Sol, 10. perde) "
            "geldiğinde 11. perdeye bas (Sol#) ve La'ya çözül.",
      ),
      LessonPoint(
        heading: "Bu hafta neye kulak vereceksin",
        body:
            "Bas avcısında akorun kök bas notasını klavyede bulacaksın. Akor kalitesinde ise "
            "minörlerin arasında beliren majör V'yi fark edeceksin. Bas avcılığında doğru "
            "oktavı bulmak önemli: aynı isimli nota farklı yükseklikte olabilir.",
        keyIdea: "Bası önce mırıldan, sonra perdelerde ara; aynı ses, aynı yükseklik.",
      ),
    ],
    exercises: [EarExerciseKind.bassHunter, EarExerciseKind.chordQuality],
    gate: MasteryGate(accuracyThreshold: 0.85, minQuestions: 25, minDaysActive: 5),
    bossTitle: "Hafta 6 Boss: Majör V Dedektörü",
  ),
  // ---------------------------------------------------------------- HAFTA 7
  EarWeek(
    weekNumber: 7,
    title: "İnversiyonlar & Slash Akorlar",
    subtitle: "C/E bas aldatmacası ve bas yürüyüşleri (C → G/B → Am)",
    theoryBrief:
        "Bas Mi çalıyorsa akor her zaman Em değildir; C/E olabilir. Bası dinle ama üstteki akorun rengini gözden kaçırma.",
    lesson: [
      LessonPoint(
        heading: "İnversiyon nedir?",
        body:
            "Normalde akorun en pes notası köküdür (C akorunda bas Do): buna kök pozisyon "
            "denir. İnversiyonda bas, kök yerine akorun 3'lüsünü (1. inversiyon) ya da "
            "5'lisini (2. inversiyon) çalar. Üstteki akor aynı kalır, sadece en alttaki nota "
            "değişir.",
        sound: ChordSound(rootMidi: 48, quality: EarChordQuality.major),
        soundLabel: "C (kök pozisyon, bas Do)",
        compareSound: SlashChordSound(bassMidi: 40, upperMidis: [52, 55, 60]),
        compareLabel: "C/E (1. inversiyon, bas Mi)",
        terms: {
          "Kök pozisyon": "Akorun en pes notasının kendi kökü olması.",
          "İnversiyon": "Akorun en pes notasının kök yerine 3'lü ya da 5'li olması.",
        },
        keyIdea: "İnversiyonda akor aynı, sadece bas değişir.",
      ),
      LessonPoint(
        heading: "Slash akor: C/E nasıl okunur?",
        body:
            "Slash notasyonu “akor / bas notası” demektir. C/E: üstte Do majör, basta Mi. Bas "
            "Mi çaldı diye akoru otomatik Em sanma! Üstteki seslerin rengine kulak ver: "
            "aydınlık bir majör duyuyorsan bu C/E'dir.",
        sound: SlashChordSound(bassMidi: 40, upperMidis: [52, 55, 60]),
        soundLabel: "C/E (bas Mi, üstte aydınlık C)",
        compareSound: ChordSound(rootMidi: 40, quality: EarChordQuality.minor),
        compareLabel: "Em (bas Mi, gölgeli)",
        terms: {
          "Slash akor": "“Akor/bas” şeklinde yazılan, bası ayrıca belirtilmiş akor (C/E).",
        },
        keyIdea: "Bas aynı olabilir; akorun adını üstteki renk söyler.",
      ),
      LessonPoint(
        heading: "Bas yürüyüşü: C → G/B → Am",
        body:
            "İnversiyonlar en çok bas yürüyüşlerinde kullanılır. C → G → Am dizisinde bas "
            "Do'dan Sol'e atlar, sonra La'ya çıkar. G yerine G/B kullanınca bas Do-Si-La diye "
            "basamak basamak iner ve geçiş pürüzsüzleşir. A ve B'de sadece basa odaklan.",
        sound: HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [47, 50, 55, 59],
            [45, 48, 52, 57],
          ],
          beatsPerChord: 2,
          bpm: 80,
        ),
        soundLabel: "C → G/B → Am (bas: Do-Si-La, basamaklı)",
        compareSound: HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [43, 47, 50, 55],
            [45, 48, 52, 57],
          ],
          beatsPerChord: 2,
          bpm: 80,
        ),
        compareLabel: "C → G → Am (bas: Do-Sol-La, sıçramalı)",
        terms: {
          "Bas yürüyüşü": "Akorlar arasında basın küçük adımlarla ilerlemesi.",
        },
        keyIdea: "Bas basamak basamak ilerliyorsa arada büyük ihtimalle bir inversiyon var.",
      ),
      LessonPoint(
        heading: "2. inversiyon: neden daha “asılı”?",
        body:
            "1. inversiyonda (bas 3'lü) akor hâlâ oldukça kararlı duyulur. 2. inversiyonda "
            "(bas 5'li) ise basla üstündeki nota arasında bir 4'lü oluşur ve akor daha "
            "çözülmemiş, asılı bir his verir. Bu yüzden 2. inversiyon genelde tek başına değil, "
            "bir geçiş ya da kapanıştan hemen önce kullanılır.",
        sound: SlashChordSound(bassMidi: 43, upperMidis: [48, 52, 55]),
        soundLabel: "C/G (2. inversiyon, bas Sol)",
        compareSound: SlashChordSound(bassMidi: 40, upperMidis: [52, 55, 60]),
        compareLabel: "C/E (1. inversiyon, bas Mi)",
        keyIdea: "Bas yürüyüşünde en “asılı” duran an genellikle bir 2. inversiyondur.",
      ),
      LessonPoint(
        heading: "İnversiyonu kulakla yakalamanın yolu",
        body:
            "Kaynakların önerdiği en güvenilir yöntem, akorun en pes notasını ayrı dinlemek. "
            "Önce bası mırıldan, sonra üstteki akorun adını söyle. İkisi aynı notaysa kök "
            "pozisyon; farklıysa ve bas akorun 3'lüsü ya da 5'liyse inversiyon. Alıştırmada "
            "“Bası ayrı dinle” düğmesini kullan.",
        tryThis:
            "Gitarda C akorunu çal, sonra 6. teli açık bırakıp (Mi) aynı akoru çal: C/E. İkisini "
            "art arda çalıp sadece en kalın sese odaklan.",
        keyIdea: "Bas = akorun adı mı? Evetse kök, hayırsa inversiyon.",
      ),
      LessonPoint(
        heading: "Gitarist taktiği: kendi bas yürüyüşünü kur",
        body:
            "İki tanıdık akor seç (C ve Am) ve aralarında basın küçük adımlarla indiği bir "
            "geçiş kur: C → G/B → Am. Amaç isimleri ezberlemek değil, basın nasıl pürüzsüz "
            "bir çizgi çizdiğini elinle ve kulağınla keşfetmek.",
        examples: [
          "G/B: 5. tel 2. perde (Si) basta, üstte G akoru",
          "C/G: 6. tel 3. perde (Sol) basta, üstte C akoru",
        ],
      ),
      LessonPoint(
        heading: "Bu hafta nasıl dinleyeceksin",
        body:
            "İnversiyon Dedektörü'nde üç seçenek var: kök pozisyon, 1. inversiyon ve 2. "
            "inversiyon. Üç seçenekte de üstteki akor birebir aynı; tek fark en pes nota. "
            "“Bası ayrı dinle” düğmesiyle bası mırıldan, sonra akorun kökü mü, 3'lüsü mü, "
            "5'lisi mi olduğuna karar ver. Bas avcısı da devam ediyor.",
        keyIdea: "Bas kökse oturmuş, 3'lüyse hafif, 5'liyse asılı.",
      ),
    ],
    exercises: [EarExerciseKind.inversionDetect, EarExerciseKind.bassHunter],
    gate: MasteryGate(accuracyThreshold: 0.85, minQuestions: 25, minDaysActive: 5),
    bossTitle: "Hafta 7 Boss: İnversiyon Tuzağı",
  ),
  // ---------------------------------------------------------------- HAFTA 8
  EarWeek(
    weekNumber: 8,
    title: "Kadanslar & Popüler Döngüler",
    subtitle: "Yarım, otantik, yanıltıcı, plagal kadans; I-V-vi-IV ve i-VI-III-VII",
    theoryBrief:
        "Kadans, cümlenin nasıl bittiğidir: V'de asılı kalır (virgül), V→I'de biter (nokta), V→vi'de şaşırtır, IV→I'de yumuşakça kapanır.",
    lesson: [
      LessonPoint(
        heading: "Kadans nedir?",
        body:
            "Kadans, bir müzik cümlesinin nasıl bittiğini anlatan kısa bir akor hareketidir. "
            "Konuşmadaki noktalama işaretleri gibidir: bazıları cümleyi bitirir, bazıları "
            "askıda bırakır, bazıları şaşırtır. Bu haftadan itibaren tek tek akorları değil, "
            "akorlar arasındaki ilişkiyi dinleyeceksin.",
        terms: {
          "Kadans": "Bir müzik cümlesini bitiren ya da askıya alan akor hareketi.",
        },
        examples: [
          "Yarım kadans: … → V (virgül, askıda)",
          "Otantik kadans: V → I (nokta, tam bitiş)",
          "Yanıltıcı kadans: V → vi (sürpriz)",
          "Plagal kadans: IV → I (yumuşak “amin”)",
        ],
        keyIdea: "Kadansı tanımak için son akora odaklan: bitti mi, askıda mı, şaşırttı mı?",
      ),
      LessonPoint(
        heading: "Yarım ve otantik kadans: virgül ve nokta",
        body:
            "V'de biten bir cümle bitmemiş hissettirir; kulak “peki sonra?” diye sorar. V'den "
            "eve (I ya da minörde i) giden hareket ise gerilimi tamamen çözer ve “bitti” "
            "hissini verir. 6. haftada duyduğun E7 → Am, otantik kadansın minördeki hâliydi.",
        sound: CadenceSound(rootMidi: 40, cadence: EarCadenceType.I_V),
        soundLabel: "Yarım kadans: I → V (virgül)",
        compareSound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.V7_i),
        compareLabel: "Otantik kadans: V7 → i (nokta)",
        terms: {
          "Yarım kadans": "V akorunda biten, askıda kalan cümle sonu.",
          "Otantik kadans": "V'den I'e giden, cümleyi kesin olarak bitiren hareket.",
        },
        keyIdea: "Son akorda rahatsız bir beklenti varsa yarım, rahatlama varsa otantik.",
      ),
      LessonPoint(
        heading: "Yanıltıcı kadans: V → vi",
        body:
            "Kulak V'den sonra eve (I) dönmeyi beklerken müzik beklenmedik şekilde vi'ye "
            "sapar: gerilim çözülür ama “yanlış” bir eve, daha hüzünlü bir yere. The "
            "Beatles'ın “Not a Second Time” (1963) şarkısında Sol majördeki bir V7, beklenen "
            "Sol yerine Mi minöre çözülür; bu geçiş dönemin eleştirmeni William Mann'ın "
            "yazısında bile dikkat çekmiştir.",
        sound: CadenceSound(rootMidi: 40, cadence: EarCadenceType.V_vi),
        soundLabel: "V → vi (sürpriz)",
        compareSound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.V7_i),
        compareLabel: "V7 → i (beklenen bitiş)",
        terms: {
          "Yanıltıcı kadans": "V'den beklenen I yerine vi'ye geçiş.",
        },
        examples: [
          "The Beatles “Not a Second Time”",
          "The Police “Every Breath You Take”: kıta döngüsü vi'ye düşen bir kesintiyle devam eder",
        ],
        keyIdea: "“Tam bitecek” derken hüzünlü bir akora düşüyorsa yanıltıcı kadans.",
      ),
      LessonPoint(
        heading: "Plagal kadans: IV → I, “amin” kapanışı",
        body:
            "Kilise ilahilerinin sonundaki “a-min” hecelerinin altında bu IV → I hareketi "
            "çalar; bu yüzden “amin kadansı” da denir. Yönlendirici ses içermediği için "
            "otantik kadanstan daha yumuşak, daha az kararlı ama huzurlu bir kapanıştır.",
        sound: CadenceSound(rootMidi: 40, cadence: EarCadenceType.IV_I),
        soundLabel: "IV → I (yumuşak kapanış)",
        compareSound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.V7_i),
        compareLabel: "V7 → i (kesin kapanış)",
        terms: {
          "Plagal kadans": "IV'ten I'e giden yumuşak kapanış (“amin kadansı”).",
        },
        keyIdea: "Kesin bir “nokta” değil, sakin bir “amin” gibiyse plagal.",
      ),
      LessonPoint(
        heading: "Dünya popunun 4 akoru: I-V-vi-IV",
        body:
            "Pop ve rock şarkılarının çok büyük kısmı I-V-vi-IV döngüsüne dayanır: ev → "
            "gerilim → hüzün → açılış. Avustralyalı komedi grubu Axis of Awesome, 2008 "
            "Edinburgh Fringe Festivali'nde başlayıp yıllar içinde büyüttüğü “4 Chords” "
            "gösterisinde bu kalıbı kullanan onlarca ünlü şarkıyı art arda çalarak bunu "
            "kanıtladı; video onlarca milyon kez izlendi.",
        sound: CadenceSound(rootMidi: 40, cadence: EarCadenceType.I_V_vi_IV),
        soundLabel: "I – V – vi – IV döngüsü",
        examples: [
          "“Let It Be” (The Beatles): C – G – Am – F",
          "Journey “Don't Stop Believin'”, Adele “Someone Like You” (Axis of Awesome listesinde)",
          "Aynı dört akor farklı sırayla da çalınabilir: vi – IV – I – V",
        ],
        keyIdea: "Bu dört akoru bir kez kulağına yerleştirirsen radyoda her gün duyarsın.",
      ),
      LessonPoint(
        heading: "Minör karşılığı: i-VI-III-VII",
        body:
            "Aynı dört akor minör bir evden başlarsa daha hüzünlü bir döngü çıkar: i-VI-III-VII "
            "(örneğin Am-F-C-G). Bu, I-V-vi-IV'ün ilgili minör karşılığıdır: aynı akor ailesi, "
            "farklı bir ev.",
        sound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.i_VI),
        soundLabel: "i → VI (hüzünlü iniş)",
        examples: [
          "The Cranberries “Zombie”: Em – C – G – D (Mi minörde i-VI-III-VII)",
        ],
        keyIdea: "Aynı akorlar; ev majörse parlak, minörse hüzünlü bir döngü.",
      ),
      LessonPoint(
        heading: "Neden sadece 4 akor bu kadar işe yarıyor?",
        body:
            "3. haftadaki aileleri hatırla. I-V-vi-IV tek bir turda üç aileyi de gezer: I "
            "(ev) → V (gerilim) → vi (evin hüzünlü akrabası) → IV (hareket) → tekrar I. Yani "
            "müziğin anlatabileceği temel “gerilim → çözülme” hikâyesinin en kısa ve en tam "
            "hâlidir.",
        keyIdea: "Ev, hareket, gerilim ve dönüş: dört akorda tam bir hikâye.",
      ),
      LessonPoint(
        heading: "Gitarist taktiği: döngüyü kulaktan avla",
        body:
            "Yeni bir şarkı duyduğunda önce genel rengi sor: majör mü minör mü? Majörse "
            "I-V-vi-IV'ü, minörse i-VI-III-VII'yi dene. Evi bulmak için şarkının bittiği ya da "
            "“oturduğu” akoru dinle. Tutmazsa aynı akorları farklı sırayla dene.",
        tryThis:
            "Radyoda ya da listende rastgele 3 şarkı aç. Her birinde 4 akorluk bir döngü olup "
            "olmadığını ve ilk akorun ev olup olmadığını tahmin et.",
      ),
      LessonPoint(
        heading: "Pentatonik köprüsü",
        body:
            "Minör pentatonik gam (1-♭3-4-5-♭7) beş notalık bir kestirmedir: bu döngülerin "
            "çoğunda kulağa “doğru” gelir. Blues'tan rock'a, Anadolu poptan metale kadar "
            "solo ve melodilerin omurgasıdır.",
        terms: {
          "Pentatonik": "Beş notalı gam; minör pentatonik 1-♭3-4-5-♭7 notalarından oluşur.",
        },
        sound: ScaleSound(notes: [45, 48, 50, 52, 55, 57]),
        soundLabel: "La minör pentatonik",
      ),
    ],
    exercises: [EarExerciseKind.cadenceRecognition],
    gate: MasteryGate(accuracyThreshold: 0.85, minQuestions: 30, minDaysActive: 5),
    bossTitle: "Hafta 8 Boss: Döngü ve Kadans Avcısı",
  ),
  // ---------------------------------------------------------------- HAFTA 9
  EarWeek(
    weekNumber: 9,
    title: "Şarkı Formu & Verse / Chorus Dinamiği",
    subtitle: "Kıta, nakarat, köprü: bölümleri kulaktan ayırmak ve enerji geçişleri",
    theoryBrief:
        "Sözler değişip ezgi aynı kalıyorsa kıta (verse); sözler ve ezgi birlikte tekrar ediyorsa nakarat (chorus); hiç benzemeyen tek seferlik bölüm köprüdür (bridge).",
    lesson: [
      LessonPoint(
        heading: "Şarkının iskeleti",
        body:
            "Çoğu pop ve rock şarkısı tanıdık bir iskelete oturur: kıta → (köprücük) → "
            "nakarat, ve genellikle bir yerde köprü. Bölümleri tanımak, şarkının akor "
            "haritasını çıkarmanın ilk adımıdır, çünkü aynı bölüm tekrar ettiğinde akorları "
            "da genellikle aynıdır.",
        terms: {
          "Kıta (verse)": "Hikâyeyi anlatan, sözleri her seferinde değişen bölüm.",
          "Köprücük (pre-chorus)": "Kıtadan nakarata gerilim biriktiren kısa geçiş.",
          "Nakarat (chorus)": "Şarkının zirvesi; sözleri ve ezgisi aynen tekrar eder.",
          "Köprü (bridge)": "Tekrar eden yapıyı kıran, genelde bir kez gelen bölüm.",
        },
        keyIdea: "Aynı bölüm geri geldiğinde akorları da genellikle aynıdır: bir kez çöz, hep kullan.",
      ),
      LessonPoint(
        heading: "Bölümleri kulaktan ayırmanın kuralları",
        body:
            "Şarkı yazımı kaynakları basit ama güvenilir kurallar veriyor. Akorları bilmen "
            "gerekmez; sadece sözlere, ezgiye ve enerjiye bak.",
        examples: [
          "Sözler değişiyor ama ezgi aynı → muhtemelen yeni bir kıta",
          "Sözler ve ezgi birlikte tekrar ediyor → nakarat",
          "Nakarat genelde daha yüksek, daha enerjik ve şarkının adını taşır",
          "Köprü çoğunlukla ikinci nakarattan sonra, son nakarattan önce gelir",
        ],
        keyIdea: "Söz + ezgi tekrar ediyorsa nakarat, sadece ezgi tekrar ediyorsa kıta.",
        tryThis:
            "Bir şarkıyı dinlerken her yeni bölüme bir harf ver: ilk tekrar eden bölüm A, "
            "farklı olan B, tek seferlik dönüm noktası C. Sonunda şarkının harf dizisini yaz "
            "(ör. A-B-A-B-C-B).",
      ),
      LessonPoint(
        heading: "Kıta kapalı, nakarat açık",
        body:
            "Kıta genellikle daha sakindir: daha az enstrüman, daha alçak ses ve daha pes bir "
            "ezgi. Nakaratta her şey “açılır”: daha fazla enstrüman, daha yüksek ses, daha tiz "
            "bir ezgi. Aşağıda kapalı ve hüzünlü bir kıta hissi ile açılan bir nakarat hissini "
            "karşılaştır; ikisi de aynı La notasından başlıyor.",
        sound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.i_VI),
        soundLabel: "Kıta hissi (kapalı, minör)",
        compareSound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.I_V_vi_IV),
        compareLabel: "Nakarat hissi (açık, genişleyen)",
        keyIdea: "Enerji yükseldi, ses açıldı, ezgi tizleşti → büyük ihtimalle nakarattasın.",
      ),
      LessonPoint(
        heading: "Enerjiyi nasıl açarlar?",
        body:
            "Nakaratın açılma hissi çoğu zaman teoriden değil, düzenlemeden gelir. Bir "
            "gitarist olarak bunu taklit etmek istersen en hızlı üç araç: vuruş yoğunluğunu "
            "artırmak, daha sert çalmak ve daha fazla açık tel içeren akor şekillerine "
            "geçmek.",
        examples: [
          "Davul ve bas kıtada sade, nakaratta tam güçte",
          "Ritim deseni tek tek aşağı vuruşlardan daha yoğun bir aşağı-yukarı desene geçer",
          "İkinci bir gitar ya da vokal katmanı eklenir",
        ],
        tryThis:
            "Aynı dört akoru önce sadece aşağı vuruşlarla ve yumuşak, sonra aşağı-yukarı "
            "desenle ve sert çal. Kıta ile nakarat arasındaki farkı elinle yarat.",
      ),
      LessonPoint(
        heading: "Köprü: beklenmedik köşe",
        body:
            "Köprünün farklı hissetmesinin en yaygın sebebi, alışılmış döngüden çıkıp yeni "
            "bir akor ya da kadans kullanmasıdır. Bazı şarkılarda köprü harmonik olarak hiç "
            "değişmez, sadece daha sakin bir düzenlemeyle kontrast yaratır. En güvenilir soru: "
            "“Bu bölüm öncekilerden farklı bir şey yapıyor mu?”",
        keyIdea: "Köprüyü tek bir işaret değil, “farklılık” hissi ele verir.",
      ),
      LessonPoint(
        heading: "Bu hafta nasıl dinleyeceksin",
        body:
            "Kadans soruları bu hafta da devam ediyor. Ek olarak her gün bir şarkıyı baştan "
            "sona sadece bölümleri takip ederek dinle: akorları bilmen gerekmez. Nakaratın "
            "genelde şarkının en açık ve en parlak kadansını taşıdığını fark edeceksin.",
        keyIdea: "Önce harita (bölümler), sonra ayrıntı (akorlar).",
      ),
    ],
    exercises: [EarExerciseKind.cadenceRecognition],
    gate: MasteryGate(accuracyThreshold: 0.85, minQuestions: 25, minDaysActive: 5),
    bossTitle: "Hafta 9 Boss: Form ve Enerji Analizi",
  ),
  // ---------------------------------------------------------------- HAFTA 10
  EarWeek(
    weekNumber: 10,
    title: "Konsolidasyon 2 & Capo / Eb Akort Tespiti",
    subtitle: "Yarım ses pes akort ve capo: duyduğun ile çaldığın arasındaki fark",
    theoryBrief:
        "Çıkardığın akorlar sürekli bemollere (E♭, A♭, B♭) düşüyorsa şarkı yarım ses pes akortlu olabilir. Açık tel çınlaması duyuyor ama ton tiz geliyorsa capo kullanılmıştır.",
    lesson: [
      LessonPoint(
        heading: "İkinci birleştirme haftası",
        body:
            "Dokuz haftada aralık, akor kalitesi, bas, inversiyon ve kadans becerilerini "
            "topladın. Bu hafta yeni teori yok; bunun yerine gerçek kayıtlarda karşına çıkan "
            "iki pratik tuzağı öğreniyorsun: alternatif akort ve capo. İkisi de “duyduğum ile "
            "gitarda bulduğum arasında bir fark var” hissi yaratır.",
        keyIdea: "Akorlar garip geliyorsa sorun kulağında değil, akortta olabilir.",
      ),
      LessonPoint(
        heading: "Yarım ses pes (E♭) akort",
        body:
            "Birçok rock ve blues kaydında gitarın tüm telleri standarttan yarım ses aşağı "
            "akort edilir. Belirtisi: standart akortla çıkardığın akorlar sürekli E♭, A♭, B♭ "
            "gibi garip bemollere düşer. Bu durumda gitarını yarım ses pes akort et; dizilim "
            "birden Em, G, C gibi tanıdık akorlara dönüşür.",
        sound: NoteSound(40),
        soundLabel: "Standart 6. tel (Mi)",
        compareSound: NoteSound(39),
        compareLabel: "Yarım ses pes 6. tel (Mi♭)",
        terms: {
          "E♭ akort": "Tüm tellerin yarım ses pes akort edilmesi: E♭-A♭-D♭-G♭-B♭-E♭.",
        },
        examples: [
          "Jimi Hendrix “Purple Haze”",
          "Stevie Ray Vaughan “Pride and Joy”",
          "Guns N' Roses “Appetite for Destruction” albümü (ör. “Paradise City”)",
        ],
        keyIdea: "Her şey bemol çıkıyorsa gitarını yarım ses pes akort etmeyi dene.",
      ),
      LessonPoint(
        heading: "Capo",
        body:
            "Capo, telleri belli bir perdede sabitleyen bir kıskaçtır ve sesi taktığın perde "
            "sayısı kadar yükseltir. 2. perdeye taktığında açık E şekli çalsan bile kulakta "
            "duyduğun F♯ majördür. Açık tel çınlamaları ve kolay akor şekilleri duyuyor ama "
            "tonu daha tiz buluyorsan capo kullanılmış olabilir.",
        sound: ChordSound(rootMidi: 40, quality: EarChordQuality.major),
        soundLabel: "E şekli, capo yok (E)",
        compareSound: ChordSound(rootMidi: 42, quality: EarChordQuality.major),
        compareLabel: "Aynı şekil, capo 2 (F♯)",
        terms: {
          "Capo": "Telleri bir perdede sabitleyen kıskaç; açık akor şekillerini daha tiz tona taşır.",
        },
        examples: [
          "Oasis “Wonderwall”: capo 2. perdede",
        ],
        keyIdea: "Akor şekli aynı, ton capo sayısı kadar yukarıda.",
      ),
      LessonPoint(
        heading: "Hangisi? Hızlı kontrol listesi",
        body:
            "Bir kayıtla gitarın uyuşmuyorsa sırayla şu soruları sor. Sıralama önemli, çünkü "
            "en sık görülen durumdan en nadirine doğru gider.",
        examples: [
          "1) Akorlar sürekli bemol mü? → yarım ses pes akort dene",
          "2) Açık tel çınlıyor ama ton tiz mi? → capo dene",
          "3) Hiçbir tanıdık kalıba oturmuyor mu? → farklı bir müzik sistemi olabilir (aşağıya bak)",
        ],
        keyIdea: "Önce akort, sonra capo, sonra sistem.",
      ),
      LessonPoint(
        heading: "Vaka analizi: Barış Manço ve “yabancı” gelen akorlar",
        body:
            "Anadolu rock'ın öncülerinden Barış Manço, Türk halk müziğinin makam ve saz "
            "geleneğini Batı rock enstrümantasyonuyla harmanladı. Makam sistemi, bu müfredatta "
            "öğrendiğin majör/minör mantığından farklı aralık ilişkileri kullanır: örneğin "
            "Hicaz gibi makamlarda Batı kulağının pek alışık olmadığı artık 2'li aralıklar "
            "geçer. Bir şarkı hiçbir tanıdık kalıba oturmuyorsa bu senin hatan olmak zorunda "
            "değil.",
        terms: {
          "Makam": "Türk müziğinin, kendine özgü aralıklar ve seyir kuralları olan ezgi sistemi.",
          "Artık 2'li": "Üç yarım seslik bir 2'li; Hicaz'ın karakteristik sesi.",
        },
        sound: ScaleSound(notes: [45, 46, 49, 50, 52]),
        soundLabel: "Hicaz'ın karakteristik açılışı (La-Si♭-Do♯-Re-Mi)",
        keyIdea: "Batı kalıplarına oturmayan şarkı, başka bir sistemden besleniyor olabilir.",
      ),
      LessonPoint(
        heading: "Bu hafta nasıl çalışacaksın",
        body:
            "Sorular yine karışık gelecek: aralık, harmonik ritim, akor kalitesi, bas avcısı, "
            "inversiyon ve kadans. Amaç, hangi beceriyi ne zaman kullanacağına anında karar "
            "verebilmek. Zorlandığın türler aralıklı tekrar kartında tekrar karşına çıkacak.",
        keyIdea: "Önce “bu ne tür bir soru?” diye düşün, sonra o türün ipucunu kullan.",
      ),
    ],
    exercises: [EarExerciseKind.interleaved],
    gate: MasteryGate(accuracyThreshold: 0.80, minQuestions: 40, minDaysActive: 5),
    isConsolidation: true,
    bossTitle: "Konsolidasyon Boss: Capo & Saha Dedektifi",
  ),
  // ---------------------------------------------------------------- HAFTA 11
  EarWeek(
    weekNumber: 11,
    title: "7'li Akorlar (Dominant 7 & Minör 7)",
    subtitle: "Blues gerilimi (E7/A7) ve yumuşak, kadife minör 7 tınısı (Em7/Am7)",
    theoryBrief:
        "7'li akoru iki katmanda dinle: önce alttaki üçlü (aydınlık mı gölgeli mi), sonra üstteki 7'li (gergin mi yumuşak mı).",
    lesson: [
      LessonPoint(
        heading: "7'li akor nedir?",
        body:
            "Triada (1-3-5) bir de 7. derece eklersen 7'li akor elde edersin. Bu tek nota "
            "akorun rengini kökten değiştirir. Bu hafta küçük 7'li (♭7) içeren iki akora "
            "odaklanıyoruz: dominant 7 ve minör 7.",
        terms: {
          "7'li akor": "Triada 7. derecenin eklenmesiyle oluşan dört notalı akor.",
          "♭7 (küçük 7'li)": "Kökten 10 yarım ses yukarıdaki nota; kökün bir tam ses altı.",
        },
        keyIdea: "7'li akoru iki katmanda dinle: alttaki üçlü + üstteki 7'li.",
      ),
      LessonPoint(
        heading: "Dominant 7: çözülmek isteyen gerilim",
        body:
            "Dominant 7 = majör triad + küçük 7'li (1-3-5-♭7). İçindeki 3'lü ile ♭7 arasında "
            "bir triton (üç tam ses) oluşur; bu, en gergin aralıklardan biridir. Bu yüzden "
            "akor parlak ama huzursuzdur, bir yere gitmek ister. Majörle karşılaştır: aynı "
            "parlaklık, ama biri yerinde duruyor, diğeri yola çıkmak istiyor.",
        sound: ChordSound(rootMidi: 45, quality: EarChordQuality.dominant7),
        soundLabel: "A7 (parlak ama huzursuz)",
        compareSound: ChordSound(rootMidi: 45, quality: EarChordQuality.major),
        compareLabel: "A (parlak ve sakin)",
        terms: {
          "Triton": "Üç tam seslik (6 yarım ses) aralık; çok gergin duyulur.",
        },
        keyIdea: "Parlak ama huzursuz, bir yere gitmek istiyorsa dominant 7.",
      ),
      LessonPoint(
        heading: "Blues: her akorun dominant olduğu dünya",
        body:
            "Normalde sadece V akoru dominant olur. Ama 12 ölçülük blues'ta I, IV ve V'nin üçü "
            "de genellikle dominant 7'li çalınır; yani ev akoru bile gerilim taşır. Bu yüzden "
            "blues hiç tam olarak “rahatlamaz” ve o karakteristik huzursuz tınısını taşır.",
        terms: {
          "12 ölçülük blues": "I7-IV7-V7 akorlarıyla kurulan 12 ölçülük klasik blues kalıbı.",
        },
        examples: [
          "Chuck Berry “Johnny B. Goode”: 12 ölçülük blues (B♭7 – E♭7 – F7)",
          "Stevie Ray Vaughan “Pride and Joy”",
        ],
        keyIdea: "Blues'un huzursuz tınısı dominant 7'den gelir.",
      ),
      LessonPoint(
        heading: "Minör 7: kadife hüzün",
        body:
            "Minör 7 = minör triad + küçük 7'li (1-♭3-5-♭7). Kaynaklar onu 7'li akorların en "
            "yumuşak ve rahat olanı olarak tanımlar: hüzünlü ama sert değil, dominant 7'nin "
            "aksine çözülmeye can atmaz. Caz, neo-soul ve modern akustik popta çok sevilir.",
        sound: ChordSound(rootMidi: 45, quality: EarChordQuality.minor7),
        soundLabel: "Am7 (yumuşak, kadife)",
        compareSound: ChordSound(rootMidi: 45, quality: EarChordQuality.minor),
        compareLabel: "Am (daha çıplak ve keskin)",
        keyIdea: "Gölgeli ama rahat, “burada kalabilirim” diyorsa minör 7.",
      ),
      LessonPoint(
        heading: "ii-V-I: caz ve popun ortak dili",
        body:
            "3. haftadaki aileleri 7'li akorlara uygulayınca en çok kullanılan kalıplardan "
            "biri çıkar: ii (hareket) → V7 (gerilim) → I (ev). Bu dizi caz standartlarının "
            "omurgasıdır, 7'lisiz basit hâli de pop şarkılarında sürekli karşına çıkar. Bir "
            "dominant 7 duyduğunda kulağın hemen ardından eve dönülmesini bekler.",
        sound: CadenceSound(rootMidi: 45, cadence: EarCadenceType.V7_i),
        soundLabel: "V7 → i: dominant 7'nin çözülüşü",
        keyIdea: "Dominant 7 bir soru, ardından gelen ev akoru cevaptır.",
      ),
      LessonPoint(
        heading: "Gitarist taktiği: bildiğin şekillerden 7'li yap",
        body:
            "Açık akor şekillerinin çoğundan tek bir parmağı kaldırarak ya da ekleyerek 7'li "
            "versiyonu elde edersin. Bu, kulağın “sade mi 7'li mi” dediği anda elinin doğru "
            "şekle anında geçmesini sağlar.",
        examples: [
          "E → E7: 4. teldeki parmağı kaldır (022100 → 020100)",
          "A → A7: 3. teldeki parmağı kaldır (x02220 → x02020)",
          "Am → Am7: 3. teldeki parmağı kaldır (x02210 → x02010)",
          "Em → Em7: 4. teldeki parmağı kaldır (022000 → 020000)",
        ],
        tryThis:
            "Her çifti art arda çal: önce sade, sonra 7'li. Her seferinde tek kelimeyle "
            "farkı söyle (“huzursuz”, “yumuşak”).",
      ),
      LessonPoint(
        heading: "Nasıl ayırt edeceksin",
        body:
            "Önce alttaki üçlüyü tanı: aydınlık mı (majör taban) gölgeli mi (minör taban)? "
            "Sonra üstteki rengi dinle: huzursuz ve “gitmek isteyen” mi, yumuşak ve "
            "“kalabilirim” diyen mi? Alıştırmada “Arpej çal” düğmesi akorun katmanlarını "
            "ayırmana yardım eder.",
        keyIdea: "Aydınlık + huzursuz = dominant 7. Gölgeli + yumuşak = minör 7.",
      ),
    ],
    exercises: [EarExerciseKind.chordQuality],
    gate: MasteryGate(accuracyThreshold: 0.85, minQuestions: 30, minDaysActive: 5),
    bossTitle: "Hafta 11 Boss: 7'li Renk İmtihanı",
  ),
  // ---------------------------------------------------------------- HAFTA 12
  EarWeek(
    weekNumber: 12,
    title: "Bağımsız Transkripsiyon & Final",
    subtitle: "Dış Sesler Protokolü ile 10 dakikada şarkı çıkarma",
    theoryBrief:
        "1) Akortu kontrol et → 2) Döngüye al → 3) Evi bul → 4) 1. vuruş basını yakala → 5) En tiz sesi dinle → 6) Kalıba oturt ve kayıtla birlikte çal.",
    lesson: [
      LessonPoint(
        heading: "Dış Sesler Protokolü",
        body:
            "On bir haftada öğrendiğin her şey tek bir rutinde birleşiyor. Adımları sırayla "
            "uygulamak, rastgele denemekten çok daha hızlı ve güvenilirdir.",
        examples: [
          "1) Akort kontrolü: akorlar bemol mü çıkıyor? (10. hafta)",
          "2) 2 ölçülük döngü, gerekirse yavaşlatılmış (5. hafta)",
          "3) Evi bul: şarkının oturduğu notayı mırıldan, majör mü minör mü? (3. ve 6. hafta)",
          "4) 1. vuruş basını yakala (1. ve 7. hafta)",
          "5) En tiz sesi/melodiyi dinle: akorun rengini verir (4. ve 11. hafta)",
          "6) Kalıba oturt (I-V-vi-IV, i-VI-III-VII…) ve kayıtla birlikte çal (8. hafta)",
        ],
        keyIdea: "Sırayla git: akort → döngü → ev → bas → renk → kalıp.",
      ),
      LessonPoint(
        heading: "Neden “dış sesler”?",
        body:
            "Bir düzenlemede en çok bilgi iki uçta gizlidir: en pes ses (bas, akorun kökünü "
            "verir) ve en tiz ses (melodi, akorun rengini ve hareketini verir). Ortadaki dolgu "
            "seslerini görmezden gelip bu iki uca odaklanmak transkripsiyonu çok hızlandırır.",
        sound: HarmonicRhythmSound(
          chords: [
            [45, 52, 57, 60],
            [41, 48, 53, 57],
            [48, 52, 55, 60],
            [43, 50, 55, 59],
          ],
          beatsPerChord: 4,
          bpm: 88,
        ),
        soundLabel: "Tam döngü (Am – F – C – G)",
        compareSound: ScaleSound(notes: [45, 41, 48, 43], stepDurationMs: 1300),
        compareLabel: "Sadece bas iskeleti (La – Fa – Do – Sol)",
        terms: {
          "Dış sesler": "Bir düzenlemedeki en pes (bas) ve en tiz (melodi) sesler.",
        },
        keyIdea: "Bas kökü, melodi rengi söyler; ortası çoğu zaman tahmin edilebilir.",
        tryThis:
            "Önce B'yi dinleyip bas iskeletini mırıldan, sonra A'yı dinlerken aynı bas çizgisini "
            "döngünün içinde takip et.",
      ),
      LessonPoint(
        heading: "Zor kayıtlar için iki teknik hile",
        body:
            "Bas bazen kayıtta çok gömülü kalır. Transkripsiyon yapanların sık kullandığı bir "
            "hile, kaydı bir oktav yukarı taşımaktır: bas, kulağın daha rahat duyduğu bir "
            "bölgeye çıkar. İkinci hile, şarkıyı yavaşlatmak; çoğu uygulama perdeyi "
            "değiştirmeden hızı düşürebilir.",
        examples: [
          "Perde kaydırma (pitch shift) ile kaydı +12 yarım ses yukarı taşı: bas daha net duyulur",
          "0.5x – 0.75x hız: notalar ayrışır, ton değişmez",
        ],
        keyIdea: "Duyamıyorsan yavaşlat ya da yukarı taşı; kulağın değil, kaydın sorunu.",
      ),
      LessonPoint(
        heading: "Hız hedefi: 10 dakika",
        body:
            "Amaç, tanımadığın bir şarkının ilk dakikasını 10 dakika içinde kulaktan "
            "çıkarabilmek: akort kontrolü, evi bulma, akor dizisini not etme. İlk denemelerde "
            "süreyi tutturamazsan endişelenme; önemli olan rutini eksiksiz uygulamak. Hız "
            "zamanla gelir.",
        tryThis:
            "Bir zamanlayıcı kur ve bilmediğin bir şarkının ilk 30 saniyesini protokolle "
            "çıkarmayı dene. Bitirince akorlara bakıp kendini kontrol et.",
      ),
      LessonPoint(
        heading: "Vaka analizi: maNga ve Eurovision",
        body:
            "2010'da maNga'nın “We Could Be the Same” şarkısı yarı finalde 118 puanla birinci, "
            "finalde 170 puanla ikinci oldu ve Türk rock'ının uluslararası sahnedeki en büyük "
            "başarılarından biri oldu. Bu şarkıyı (ya da sevdiğin herhangi bir rock parçasını) "
            "final sınavın olarak kullan: protokolün altı adımını uygula.",
        keyIdea: "Yoğun prodüksiyonlu bir rock şarkısında protokol işliyorsa hedefe ulaştın.",
      ),
      LessonPoint(
        heading: "Bu haftadan sonra",
        body:
            "Final Boss'u geçtiğinde müfredat biter ama pratik bitmez. Bu protokolü yeni "
            "şarkılarla tekrar tekrar uygula; aralıklı tekrar kartı zorlandığın sesleri sana "
            "geri getirmeye devam edecek. Zamanla altı adımı düşünmeden uygulamaya "
            "başlayacaksın; işte o an artık “kulaktan çalan” biri olduğun andır.",
        keyIdea: "Müfredat biter, kulak eğitimi bitmez: her yeni şarkı bir alıştırmadır.",
      ),
    ],
    exercises: [EarExerciseKind.interleaved],
    gate: MasteryGate(accuracyThreshold: 0.85, minQuestions: 50, minDaysActive: 6),
    bossTitle: "Final Şampiyonluk: 12. Hafta Transkripsiyon Ustası",
  ),
];

/// Hafta numarasına göre müfredat haftası (aralık dışıysa en yakın uç).
EarWeek earWeekByNumber(int weekNumber) {
  for (final w in earCurriculumWeeks) {
    if (w.weekNumber == weekNumber) return w;
  }
  return weekNumber < 1 ? earCurriculumWeeks.first : earCurriculumWeeks.last;
}

/// [weekNumber] dahil o haftaya kadar tanıtılmış somut egzersiz türleri
/// (karışık/konsolidasyon haftalarının soru havuzu).
List<EarExerciseKind> earKindsIntroducedBy(int weekNumber) {
  final out = <EarExerciseKind>[];
  for (final w in earCurriculumWeeks) {
    if (w.weekNumber > weekNumber) break;
    for (final k in w.exercises) {
      if (k != EarExerciseKind.interleaved && !out.contains(k)) out.add(k);
    }
  }
  return out.isEmpty ? const [EarExerciseKind.intervalBlind] : out;
}

/// Bir haftanın egzersiz listesindeki "karışık" öğeyi somut türlere açar.
List<EarExerciseKind> earExpandKinds(EarWeek week, Iterable<EarExerciseKind> kinds) {
  final out = <EarExerciseKind>[];
  for (final k in kinds) {
    final expanded = k == EarExerciseKind.interleaved
        ? earKindsIntroducedBy(week.weekNumber)
        : [k];
    for (final e in expanded) {
      if (!out.contains(e)) out.add(e);
    }
  }
  return out;
}
