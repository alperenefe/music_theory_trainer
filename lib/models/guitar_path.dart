import 'chord_shape.dart';

/// Gitar yolundaki bir adımın türü.
enum GuitarStepKind {
  /// Okunacak kısa öğretici kart (puanlanmaz, "Okudum" ile tamamlanır).
  info,

  /// Mevcut akort cihazını açar; "Akort ettim" ile tamamlanır.
  tuner,

  /// Altı açık teli sırayla çal (YIN ile perde doğrulanır).
  openStrings,

  /// Tek bir akoru tut ve çal (akor algılayıcı doğrular).
  chordPlay,

  /// İki akor arasında bir dakikada kaç değişim.
  changes,

  /// Metronomla vuruş kalıbı çal (vuruş algılayıcı + ritim değerlendirici).
  strum,

  /// Akor döngüsünü ölçü ölçü çal (akor adları görünür).
  progression,

  /// Akor döngüsünü ÖNCE DİNLE, adlarını göstermeden kulaktan bulup çal.
  earPlay,
}

final class InfoBlock {
  const InfoBlock(this.heading, this.body);
  final String heading;
  final String body;
}

final class GuitarStep {
  const GuitarStep({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle = '',
    this.blocks = const [],
    this.chordIds = const [],
    this.patternId,
    this.bpm,
    this.target,
    this.bars,
  });

  /// Kalıcı kimlik (yıldızlar bununla saklanır): değiştirme!
  final String id;
  final GuitarStepKind kind;
  final String title;
  final String subtitle;

  /// [GuitarStepKind.info] için kartlar.
  final List<InfoBlock> blocks;

  /// info: gösterilecek akor şemaları; chordPlay: [0] hedef; changes: [0],[1];
  /// strum: [0] üzerinde çalınır; progression/earPlay: döngünün akorları.
  final List<String> chordIds;
  final String? patternId;
  final int? bpm;

  /// changes için dakikada hedef değişim sayısı.
  final int? target;

  /// strum için ölçü sayısı; progression/earPlay için TOPLAM ölçü sayısı.
  final int? bars;

  List<ChordShape> get chords => [for (final id in chordIds) ChordLibrary.byId(id)];

  bool get isScored =>
      kind != GuitarStepKind.info && kind != GuitarStepKind.tuner;
}

final class GuitarLesson {
  const GuitarLesson({
    required this.id,
    required this.title,
    required this.goal,
    required this.steps,
  });

  final String id;
  final String title;

  /// Bu dersin sonunda neyi yapabileceksin?
  final String goal;
  final List<GuitarStep> steps;
}

final class GuitarLevel {
  const GuitarLevel({
    required this.number,
    required this.title,
    required this.subtitle,
    required this.lessons,
    this.earLink,
  });

  final int number;
  final String title;
  final String subtitle;
  final List<GuitarLesson> lessons;

  /// Bu seviyenin hangi kulak eğitimi haftasıyla örtüştüğü (varsa).
  final String? earLink;

  List<GuitarStep> get steps => [for (final l in lessons) ...l.steps];
}

/// Gitar çalmayı sıfırdan öğreten yol.
///
/// Sıra, JustinGuitar'ın kanıtlanmış beginner sırasını izler (D–A → E → Em–Am
/// → Dm → C–G, bir dakikada akor değişimi, metronom, "klasik" kalıp). Yousician
/// gibi seviyeler KİLİTLİ DEĞİL: istediğin yerden başlayabilirsin; uygulama
/// yalnızca bir sonraki önerilen adımı gösterir. Kulak müfredatıyla bağ:
/// 5. seviyedeki G–D–Em–C döngüsü 8. haftadaki I–V–vi–IV'tür.
abstract final class GuitarPath {
  static const levels = <GuitarLevel>[
    // ---------------------------------------------------------------- 0
    GuitarLevel(
      number: 0,
      title: 'Başlamadan önce',
      subtitle: 'Gitarı tut, akort et, açık telleri tanı',
      lessons: [
        GuitarLesson(
          id: 'l0a',
          title: 'Gitarı hazırla',
          goal: 'Doğru oturuş, akortlu gitar ve akor şemasını okuyabilmek.',
          steps: [
            GuitarStep(
              id: 'l0a.hold',
              kind: GuitarStepKind.info,
              title: 'Gitarı nasıl tutarsın?',
              blocks: [
                InfoBlock(
                  'Otur, sırtını dik tut',
                  'Gitarın gövdesini bacağının üstüne yasla; sap hafifçe yukarı baksın. '
                      'Omuzların gevşek olsun, çünkü gerginlik hızlı yorulmaya yol açar.',
                ),
                InfoBlock(
                  'Basan el',
                  'Başparmağın sapın arkasında dursun, boynu sıkma. Teli parmağın '
                      'yastığıyla değil UCUYLA ve perdeye yakın bas; böylece temiz ses çıkar.',
                ),
                InfoBlock(
                  'Vuran el',
                  'Pena işaret parmağı ile başparmak arasında, gevşek tutulur. Vuruşu '
                      'koldan değil bilekten ver.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l0a.tune',
              kind: GuitarStepKind.tuner,
              title: 'Gitarını akort et',
              subtitle: 'Akortsuz gitarla çalışmak kulağı yanıltır.',
            ),
            GuitarStep(
              id: 'l0a.boxes',
              kind: GuitarStepKind.info,
              title: 'Akor şeması nasıl okunur?',
              chordIds: ['Em'],
              blocks: [
                InfoBlock(
                  'Teller ve perdeler',
                  'Dikey çizgiler teller (solda en kalın Mi teli), yatay çizgiler perdelerdir.',
                ),
                InfoBlock(
                  'Noktalar',
                  'Nokta, parmağını koyacağın yerdir; içindeki sayı hangi parmak olduğunu '
                      'söyler: 1 işaret, 2 orta, 3 yüzük, 4 serçe.',
                ),
                InfoBlock(
                  'O ve X',
                  'Telin üstündeki O "boş tel çal", X ise "bu teli çalma" demektir.',
                ),
              ],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l0b',
          title: 'Açık teller',
          goal: 'Altı telin adını bilmek ve her birini temiz çalmak.',
          steps: [
            GuitarStep(
              id: 'l0b.names',
              kind: GuitarStepKind.info,
              title: 'Altı telin adı',
              blocks: [
                InfoBlock(
                  'Kalından inceye',
                  'Mi – La – Re – Sol – Si – mi. Yani 6. tel (en kalın) Mi, 1. tel (en ince) '
                      'yine mi\'dir, iki oktav arayla.',
                ),
                InfoBlock(
                  'Neden önemli?',
                  'Bütün akor şemalarını ve kulak eğitimindeki bas notasını bu isimlerle '
                      'okuyacaksın.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l0b.open',
              kind: GuitarStepKind.openStrings,
              title: 'Açık telleri çal',
              subtitle: 'Sırayla her teli çal; uygulama perdeyi dinler.',
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 1
    GuitarLevel(
      number: 1,
      title: 'İlk akorlar: D ve A',
      subtitle: 'İki akor, ilk akor değişimleri, ilk ritim',
      lessons: [
        GuitarLesson(
          id: 'l1a',
          title: 'D akoru',
          goal: 'D akorunu temiz ve altı değil dört tel olarak çalmak.',
          steps: [
            GuitarStep(
              id: 'l1a.info',
              kind: GuitarStepKind.info,
              title: 'D akoru',
              chordIds: ['D'],
              blocks: [
                InfoBlock('Şekil', 'Üç parmak, üç ince telde bir üçgen oluşturur.'),
                InfoBlock(
                  'Dikkat',
                  'Sadece alt dört tel çalınır. 5. ve 6. tele vurmamaya çalış; yanlışlıkla '
                      'çalarsan akor çamurlaşır.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l1a.play',
              kind: GuitarStepKind.chordPlay,
              title: 'D çal',
              chordIds: ['D'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l1b',
          title: 'A akoru',
          goal: 'A akorunu temiz çalmak.',
          steps: [
            GuitarStep(
              id: 'l1b.info',
              kind: GuitarStepKind.info,
              title: 'A akoru',
              chordIds: ['A'],
              blocks: [
                InfoBlock('Şekil', 'Üç parmak yan yana, hepsi 2. perdede.'),
                InfoBlock(
                  'Dikkat',
                  '6. tel çalınmaz. En ince telin boş çalındığından emin ol: orta parmağın '
                      'altındaki tele hafifçe değiyorsa ses boğuk çıkar.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l1b.play',
              kind: GuitarStepKind.chordPlay,
              title: 'A çal',
              chordIds: ['A'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l1c',
          title: 'Akor değiştirme',
          goal: 'D ve A arasında dakikada en az 15 kez gidip gelmek.',
          steps: [
            GuitarStep(
              id: 'l1c.info',
              kind: GuitarStepKind.info,
              title: 'Akor değiştirmenin sırrı',
              blocks: [
                InfoBlock(
                  'Parmakları birlikte hareket ettir',
                  'Parmakları tek tek değil, tek bir "tutuş" gibi aynı anda kaldır ve koy.',
                ),
                InfoBlock(
                  'Elinin yerini öğrensin',
                  'Şekle bakmadan değiştirmeye çalış. İlk başta zor ama kas hafızası tam '
                      'olarak böyle oluşur.',
                ),
                InfoBlock(
                  'Önce düzgün, sonra hızlı',
                  'Bir dakikada akor değişimi egzersizinde amaç: 15, sonra 30, sonunda 60 '
                      'değişim. Hız sonradan kendiliğinden gelir.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l1c.changes',
              kind: GuitarStepKind.changes,
              title: 'D ↔ A',
              chordIds: ['D', 'A'],
              target: 15,
            ),
          ],
        ),
        GuitarLesson(
          id: 'l1d',
          title: 'İlk ritim',
          goal: 'Metronoma uyarak dört aşağı vuruş çalmak.',
          steps: [
            GuitarStep(
              id: 'l1d.strum',
              kind: GuitarStepKind.strum,
              title: 'D ile dört vuruş',
              chordIds: ['D'],
              patternId: 'quarters',
              bpm: 60,
              bars: 4,
            ),
            GuitarStep(
              id: 'l1d.strum2',
              kind: GuitarStepKind.strum,
              title: 'A ile dört vuruş',
              chordIds: ['A'],
              patternId: 'quarters',
              bpm: 70,
              bars: 4,
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 2
    GuitarLevel(
      number: 2,
      title: 'E akoru ve üç akorlu şarkılar',
      subtitle: 'Üç akor, yüzlerce şarkı',
      lessons: [
        GuitarLesson(
          id: 'l2a',
          title: 'E akoru',
          goal: 'E akorunu çalmak.',
          steps: [
            GuitarStep(
              id: 'l2a.info',
              kind: GuitarStepKind.info,
              title: 'E akoru',
              chordIds: ['E'],
              blocks: [
                InfoBlock(
                  'A ile akrabası',
                  'E akoru, A akorunun şeklinin bir tel aşağıya (kalına) kaydırılmış hâlidir; '
                      'ek olarak bir işaret parmağı gelir.',
                ),
                InfoBlock('Dikkat', 'Altı tel de çalınır.'),
              ],
            ),
            GuitarStep(
              id: 'l2a.play',
              kind: GuitarStepKind.chordPlay,
              title: 'E çal',
              chordIds: ['E'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l2b',
          title: 'Değişim pratiği',
          goal: 'D, A ve E arasında rahat geçiş yapmak.',
          steps: [
            GuitarStep(
              id: 'l2b.de',
              kind: GuitarStepKind.changes,
              title: 'D ↔ E',
              chordIds: ['D', 'E'],
              target: 20,
            ),
            GuitarStep(
              id: 'l2b.ae',
              kind: GuitarStepKind.changes,
              title: 'A ↔ E',
              chordIds: ['A', 'E'],
              target: 20,
            ),
          ],
        ),
        GuitarLesson(
          id: 'l2c',
          title: 'Metronomla vuruş',
          goal: 'Sabit tempoda düzgün aşağı vuruş çalmak.',
          steps: [
            GuitarStep(
              id: 'l2c.strum',
              kind: GuitarStepKind.strum,
              title: 'E ile dört vuruş',
              chordIds: ['E'],
              patternId: 'quarters',
              bpm: 80,
              bars: 4,
            ),
            GuitarStep(
              id: 'l2c.prog',
              kind: GuitarStepKind.progression,
              title: 'A – D – E döngüsü',
              subtitle: 'Üç akorlu rock/blues döngüsü',
              chordIds: ['A', 'D', 'E', 'A'],
              patternId: 'quarters',
              bpm: 70,
              bars: 8,
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 3
    GuitarLevel(
      number: 3,
      title: 'Minör akorlar: Em ve Am',
      subtitle: 'Hüzünlü renkler ve yukarı vuruş',
      earLink: '4. hafta: majör ile minörü ayırt etmeyi kulak eğitiminde de çalışırsın.',
      lessons: [
        GuitarLesson(
          id: 'l3a',
          title: 'Em akoru',
          goal: 'Em akorunu çalmak.',
          steps: [
            GuitarStep(
              id: 'l3a.info',
              kind: GuitarStepKind.info,
              title: 'Em, en kolay akor',
              chordIds: ['Em'],
              blocks: [
                InfoBlock(
                  'Şekil',
                  'Sadece iki parmak ve altı tel. E akorundan işaret parmağını kaldırınca '
                      'Em olur: tek bir parmak majör ile minörü ayırır.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l3a.play',
              kind: GuitarStepKind.chordPlay,
              title: 'Em çal',
              chordIds: ['Em'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l3b',
          title: 'Am akoru',
          goal: 'Am akorunu çalmak.',
          steps: [
            GuitarStep(
              id: 'l3b.info',
              kind: GuitarStepKind.info,
              title: 'Am akoru',
              chordIds: ['Am'],
              blocks: [
                InfoBlock(
                  'E ile benzerlik',
                  'Am, E akorunun şeklidir ama bütün şekil bir tel ince tarafa kaymıştır '
                      've 6. tel çalınmaz.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l3b.play',
              kind: GuitarStepKind.chordPlay,
              title: 'Am çal',
              chordIds: ['Am'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l3c',
          title: 'Minör değişimler',
          goal: 'Em, Am ve E arasında geçiş yapmak.',
          steps: [
            GuitarStep(
              id: 'l3c.ema',
              kind: GuitarStepKind.changes,
              title: 'Em ↔ Am',
              chordIds: ['Em', 'Am'],
              target: 25,
            ),
            GuitarStep(
              id: 'l3c.ae',
              kind: GuitarStepKind.changes,
              title: 'Am ↔ E',
              chordIds: ['Am', 'E'],
              target: 20,
            ),
          ],
        ),
        GuitarLesson(
          id: 'l3d',
          title: 'Aşağı ve yukarı vuruş',
          goal: 'Sekizlik aşağı-yukarı vuruşu sarkaç gibi çalmak.',
          steps: [
            GuitarStep(
              id: 'l3d.eighths',
              kind: GuitarStepKind.strum,
              title: 'Em ile aşağı-yukarı',
              chordIds: ['Em'],
              patternId: 'eighths',
              bpm: 70,
              bars: 4,
            ),
            GuitarStep(
              id: 'l3d.classic',
              kind: GuitarStepKind.strum,
              title: 'Am ile klasik kalıp',
              chordIds: ['Am'],
              patternId: 'classic',
              bpm: 70,
              bars: 4,
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 4
    GuitarLevel(
      number: 4,
      title: 'Dm ve evrensel kalıp',
      subtitle: 'Üç minör akor, pop müziğin ritmi',
      lessons: [
        GuitarLesson(
          id: 'l4a',
          title: 'Dm akoru',
          goal: 'Dm akorunu çalmak ve Am ile birlikte kullanmak.',
          steps: [
            GuitarStep(
              id: 'l4a.info',
              kind: GuitarStepKind.info,
              title: 'Dm akoru',
              chordIds: ['Dm'],
              blocks: [
                InfoBlock(
                  'D ile fark',
                  'D akorunun şekline çok benzer; fark en ince telde: 1. perdeye bas.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l4a.play',
              kind: GuitarStepKind.chordPlay,
              title: 'Dm çal',
              chordIds: ['Dm'],
            ),
            GuitarStep(
              id: 'l4a.changes',
              kind: GuitarStepKind.changes,
              title: 'Am ↔ Dm',
              chordIds: ['Am', 'Dm'],
              target: 20,
            ),
          ],
        ),
        GuitarLesson(
          id: 'l4b',
          title: 'Kalıpları pekiştir',
          goal: 'Klasik ve evrensel kalıpları 80 BPM\'de çalmak.',
          steps: [
            GuitarStep(
              id: 'l4b.classic',
              kind: GuitarStepKind.strum,
              title: 'Klasik kalıp, 80 BPM',
              chordIds: ['Am'],
              patternId: 'classic',
              bpm: 80,
              bars: 4,
            ),
            GuitarStep(
              id: 'l4b.universal',
              kind: GuitarStepKind.strum,
              title: 'Evrensel kalıp',
              chordIds: ['Em'],
              patternId: 'universal',
              bpm: 80,
              bars: 4,
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 5
    GuitarLevel(
      number: 5,
      title: 'C ve G: pop döngüleri',
      subtitle: 'Dünya popunun 4 akorlu döngüsü',
      earLink: '8. hafta: I–V–vi–IV döngüsünü kulakla tanıyorsun; burada G–D–Em–C olarak çalıyorsun.',
      lessons: [
        GuitarLesson(
          id: 'l5a',
          title: 'C akoru',
          goal: 'C akorunu çalmak.',
          steps: [
            GuitarStep(
              id: 'l5a.info',
              kind: GuitarStepKind.info,
              title: 'C akoru',
              chordIds: ['C'],
              blocks: [
                InfoBlock(
                  'Şekil',
                  'Parmaklar merdiven gibi iner: 3. teldeki yüzük parmağı, 2. perdedeki orta '
                      'parmak, 1. perdedeki işaret parmağı. 6. tel çalınmaz.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l5a.play',
              kind: GuitarStepKind.chordPlay,
              title: 'C çal',
              chordIds: ['C'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l5b',
          title: 'G akoru',
          goal: 'G akorunu çalmak.',
          steps: [
            GuitarStep(
              id: 'l5b.info',
              kind: GuitarStepKind.info,
              title: 'G akoru',
              chordIds: ['G'],
              blocks: [
                InfoBlock(
                  'Şekil',
                  'Parmakların arası geniş; başta zor gelmesi normal. Altı telin hepsi çalınır.',
                ),
                InfoBlock(
                  'İpucu',
                  'Parmakları kaldırmadan önce hangi telde olduklarını bil: yüzük parmağı en '
                      'ince tele, orta parmak 6. tele gider.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l5b.play',
              kind: GuitarStepKind.chordPlay,
              title: 'G çal',
              chordIds: ['G'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l5c',
          title: 'Pop değişimleri',
          goal: 'G, D, Em ve C arasında geçiş yapmak.',
          steps: [
            GuitarStep(
              id: 'l5c.cg',
              kind: GuitarStepKind.changes,
              title: 'C ↔ G',
              chordIds: ['C', 'G'],
              target: 20,
            ),
            GuitarStep(
              id: 'l5c.gd',
              kind: GuitarStepKind.changes,
              title: 'G ↔ D',
              chordIds: ['G', 'D'],
              target: 20,
            ),
            GuitarStep(
              id: 'l5c.emc',
              kind: GuitarStepKind.changes,
              title: 'Em ↔ C',
              chordIds: ['Em', 'C'],
              target: 20,
            ),
          ],
        ),
        GuitarLesson(
          id: 'l5d',
          title: 'G – D – Em – C döngüsü',
          goal: 'Dört akorlu döngüyü metronomla çalmak.',
          steps: [
            GuitarStep(
              id: 'l5d.loop',
              kind: GuitarStepKind.progression,
              title: 'G – D – Em – C',
              subtitle: 'I – V – vi – IV (sol majörde)',
              chordIds: ['G', 'D', 'Em', 'C'],
              patternId: 'quarters',
              bpm: 70,
              bars: 8,
            ),
            GuitarStep(
              id: 'l5d.loop2',
              kind: GuitarStepKind.progression,
              title: 'Aynı döngü, evrensel kalıpla',
              chordIds: ['G', 'D', 'Em', 'C'],
              patternId: 'universal',
              bpm: 80,
              bars: 8,
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 6
    GuitarLevel(
      number: 6,
      title: '7\'li akorlar ve blues',
      subtitle: 'Tek parmakla yeni renk',
      earLink: '11. hafta: dominant 7\'nin gerilimini kulak eğitiminde duyuyorsun.',
      lessons: [
        GuitarLesson(
          id: 'l6a',
          title: 'E7, A7, D7',
          goal: 'Üç dominant 7\'li akoru çalmak.',
          steps: [
            GuitarStep(
              id: 'l6a.info',
              kind: GuitarStepKind.info,
              title: '7\'li akorlar',
              chordIds: ['E7', 'A7', 'D7'],
              blocks: [
                InfoBlock(
                  'Bir parmak farkı',
                  'E ve A akorlarından bir parmağı kaldırınca E7 ve A7 olur: blues sesi '
                      'geliyor. D7 ise D akorunun biraz farklı bir şeklidir.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l6a.e7',
              kind: GuitarStepKind.chordPlay,
              title: 'E7 çal',
              chordIds: ['E7'],
            ),
            GuitarStep(
              id: 'l6a.a7',
              kind: GuitarStepKind.chordPlay,
              title: 'A7 çal',
              chordIds: ['A7'],
            ),
            GuitarStep(
              id: 'l6a.d7',
              kind: GuitarStepKind.chordPlay,
              title: 'D7 çal',
              chordIds: ['D7'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l6b',
          title: '12 ölçülük blues',
          goal: 'La\'da 12 ölçülük bluesu baştan sona çalmak.',
          steps: [
            GuitarStep(
              id: 'l6b.info',
              kind: GuitarStepKind.info,
              title: '12 ölçülük blues',
              chordIds: ['A7', 'D7', 'E7'],
              blocks: [
                InfoBlock(
                  'Kalıp',
                  'A7 (4 ölçü) – D7 (2) – A7 (2) – E7 (1) – D7 (1) – A7 (1) – E7 (1). '
                      'Rock\'n\'roll ve blues şarkılarının büyük kısmı bu 12 ölçüdür.',
                ),
              ],
            ),
            GuitarStep(
              id: 'l6b.blues',
              kind: GuitarStepKind.progression,
              title: 'La\'da 12 ölçülük blues',
              chordIds: [
                'A7', 'A7', 'A7', 'A7', 'D7', 'D7', 'A7', 'A7', 'E7', 'D7', 'A7', 'E7',
              ],
              patternId: 'quarters',
              bpm: 80,
              bars: 12,
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 7
    GuitarLevel(
      number: 7,
      title: 'Sus ve yumuşak renkler',
      subtitle: 'Akustik şarkıların tınısı',
      earLink: '4. ve 11. hafta: sus2 ve minör 7 renklerini kulakla ayırt ediyorsun.',
      lessons: [
        GuitarLesson(
          id: 'l7a',
          title: 'Asus2 ve Dsus2',
          goal: 'İki sus2 akorunu çalmak.',
          steps: [
            GuitarStep(
              id: 'l7a.as',
              kind: GuitarStepKind.chordPlay,
              title: 'Asus2 çal',
              chordIds: ['Asus2'],
            ),
            GuitarStep(
              id: 'l7a.ds',
              kind: GuitarStepKind.chordPlay,
              title: 'Dsus2 çal',
              chordIds: ['Dsus2'],
            ),
          ],
        ),
        GuitarLesson(
          id: 'l7b',
          title: 'Em7 ve Am7',
          goal: 'Minör 7\'li akorları çalmak ve minörden farkını duymak.',
          steps: [
            GuitarStep(
              id: 'l7b.em7',
              kind: GuitarStepKind.chordPlay,
              title: 'Em7 çal',
              chordIds: ['Em7'],
            ),
            GuitarStep(
              id: 'l7b.am7',
              kind: GuitarStepKind.chordPlay,
              title: 'Am7 çal',
              chordIds: ['Am7'],
            ),
            GuitarStep(
              id: 'l7b.ch',
              kind: GuitarStepKind.changes,
              title: 'Em ↔ Em7',
              chordIds: ['Em', 'Em7'],
              target: 30,
            ),
          ],
        ),
      ],
    ),
    // ---------------------------------------------------------------- 8
    GuitarLevel(
      number: 8,
      title: 'Duy → Çal',
      subtitle: 'Kulağınla bul, gitarında çal',
      earLink: 'Kulak eğitimi ile gitar çalmanın buluştuğu yer.',
      lessons: [
        GuitarLesson(
          id: 'l8a',
          title: 'Döngüyü kulaktan bul',
          goal: 'Duyduğun akor dizisini adlarına bakmadan gitarında çalmak.',
          steps: [
            GuitarStep(
              id: 'l8a.info',
              kind: GuitarStepKind.info,
              title: 'Nasıl çalışır?',
              blocks: [
                InfoBlock(
                  'Dinle',
                  'Uygulama dört akorluk bir döngü çalar; akor adları gösterilmez. İstediğin '
                      'kadar tekrar dinleyebilirsin.',
                ),
                InfoBlock(
                  'Bul',
                  'Önce evi (ilk akoru) bul: döngünün sonunda "rahatladığın" akor. Sonra '
                      'diğerlerini sırayla dene. Bulduğun her akoru çal; uygulama doğru mu '
                      'diye dinler.',
                ),
                InfoBlock(
                  'İpucu',
                  'Bas notayı mırıldan: akorun adı çoğunlukla bastaki notadır (kulak '
                      'eğitimi 1. hafta).',
                ),
              ],
            ),
            GuitarStep(
              id: 'l8a.major',
              kind: GuitarStepKind.earPlay,
              title: 'Pop döngüsü (majör)',
              subtitle: 'I – V – vi – IV',
              chordIds: ['G', 'D', 'Em', 'C'],
              bpm: 70,
            ),
            GuitarStep(
              id: 'l8a.minor',
              kind: GuitarStepKind.earPlay,
              title: 'Minör döngü',
              subtitle: 'i – VI – III – VII',
              chordIds: ['Em', 'C', 'G', 'D'],
              bpm: 70,
            ),
            GuitarStep(
              id: 'l8a.blues',
              kind: GuitarStepKind.earPlay,
              title: 'Blues üçlüsü',
              subtitle: 'I7 – IV7 – V7',
              chordIds: ['A7', 'D7', 'E7'],
              bpm: 70,
            ),
          ],
        ),
      ],
    ),
  ];

  static List<GuitarStep> get allSteps => [for (final l in levels) ...l.steps];

  static GuitarStep? stepById(String id) {
    for (final s in allSteps) {
      if (s.id == id) return s;
    }
    return null;
  }

  static GuitarLesson? lessonOfStep(String stepId) {
    for (final lv in levels) {
      for (final l in lv.lessons) {
        if (l.steps.any((s) => s.id == stepId)) return l;
      }
    }
    return null;
  }

  /// Bir dersin yıldızı: tüm puanlanan adımların en azından birer yıldızı varsa
  /// ortalamaları (aşağı yuvarlanmış, en az 1); aksi hâlde 0.
  static int lessonStars(GuitarLesson lesson, Map<String, int> stars) {
    final scored = lesson.steps.where((s) => s.isScored).toList();
    final all = lesson.steps;
    // Bilgi/akort adımları "tamamlandı" için en az 1 yıldız ister.
    for (final s in all) {
      if ((stars[s.id] ?? 0) < 1) return 0;
    }
    if (scored.isEmpty) return 3;
    var sum = 0;
    for (final s in scored) {
      sum += stars[s.id] ?? 0;
    }
    return (sum ~/ scored.length).clamp(1, 3);
  }

  /// İlk tamamlanmamış adım (Yousician'daki gibi "önerilen"; seviyeler kilitli değil).
  static GuitarStep? nextStep(Map<String, int> stars) {
    for (final s in allSteps) {
      if ((stars[s.id] ?? 0) < 1) return s;
    }
    return null;
  }

  static int totalStars(Map<String, int> stars) {
    var sum = 0;
    for (final s in allSteps) {
      sum += stars[s.id] ?? 0;
    }
    return sum;
  }
}
