/// Açık pozisyonda bir gitar akor şekli. Teller pesten tize: 6. (Mi) … 1. (mi).
///
/// [frets]: her tel için perde; 0 = boş tel, -1 = çalınmaz (susturulmuş).
/// [fingers]: aynı sırayla parmak numarası (1 işaret … 4 serçe); 0 = parmak yok.
final class ChordShape {
  const ChordShape({
    required this.id,
    required this.symbol,
    required this.nameTr,
    required this.frets,
    required this.fingers,
    required this.tip,
  });

  final String id;

  /// Kısa gösterim: `Em`, `A7`.
  final String symbol;

  /// Türkçe okunuş: `Mi minör`.
  final String nameTr;
  final List<int> frets;
  final List<int> fingers;

  /// Bu akor için tek cümlelik ipucu.
  final String tip;

  /// Standart akort: E2 A2 D3 G3 B3 E4.
  static const openStringMidi = [40, 45, 50, 55, 59, 64];
  static const stringNamesTr = ['6. tel (kalın Mi)', '5. tel (La)', '4. tel (Re)', '3. tel (Sol)', '2. tel (Si)', '1. tel (ince mi)'];

  /// Çalınan tellerin MIDI notaları (pesten tize).
  List<int> get midis => [
        for (var s = 0; s < 6; s++)
          if (frets[s] >= 0) openStringMidi[s] + frets[s],
      ];

  /// Çalınan tellerin indeksleri (0 = 6. tel).
  List<int> get playedStrings => [
        for (var s = 0; s < 6; s++)
          if (frets[s] >= 0) s,
      ];

  int get mutedCount => frets.where((f) => f < 0).length;

  @override
  String toString() => '$symbol(${frets.join(',')})';
}

/// Açık pozisyon akor kütüphanesi (sıra JustinGuitar'ın öğretme sırasına yakın).
abstract final class ChordLibrary {
  static const d = ChordShape(
    id: 'D',
    symbol: 'D',
    nameTr: 'Re majör',
    frets: [-1, -1, 0, 2, 3, 2],
    fingers: [0, 0, 0, 1, 3, 2],
    tip: 'Sadece alt 4 tel çalınır; 5. ve 6. tele dokunma.',
  );
  static const a = ChordShape(
    id: 'A',
    symbol: 'A',
    nameTr: 'La majör',
    frets: [-1, 0, 2, 2, 2, 0],
    fingers: [0, 0, 1, 2, 3, 0],
    tip: 'Üç parmak yan yana 2. perdede; 6. tel çalınmaz.',
  );
  static const e = ChordShape(
    id: 'E',
    symbol: 'E',
    nameTr: 'Mi majör',
    frets: [0, 2, 2, 1, 0, 0],
    fingers: [0, 2, 3, 1, 0, 0],
    tip: 'Altı teli de çal. Bu şekil A akorunun bir tel kaydırılmış hâli.',
  );
  static const em = ChordShape(
    id: 'Em',
    symbol: 'Em',
    nameTr: 'Mi minör',
    frets: [0, 2, 2, 0, 0, 0],
    fingers: [0, 2, 3, 0, 0, 0],
    tip: 'En kolay akor: iki parmak, altı tel.',
  );
  static const am = ChordShape(
    id: 'Am',
    symbol: 'Am',
    nameTr: 'La minör',
    frets: [-1, 0, 2, 2, 1, 0],
    fingers: [0, 0, 2, 3, 1, 0],
    tip: 'E majör şekliyle aynı, sadece işaret parmağı bir tel yukarıda.',
  );
  static const dm = ChordShape(
    id: 'Dm',
    symbol: 'Dm',
    nameTr: 'Re minör',
    frets: [-1, -1, 0, 2, 3, 1],
    fingers: [0, 0, 0, 2, 3, 1],
    tip: 'D akoruna benzer ama en ince telde 1. perde.',
  );
  static const c = ChordShape(
    id: 'C',
    symbol: 'C',
    nameTr: 'Do majör',
    frets: [-1, 3, 2, 0, 1, 0],
    fingers: [0, 3, 2, 0, 1, 0],
    tip: 'Parmaklar merdiven gibi; 6. tel çalınmaz.',
  );
  static const g = ChordShape(
    id: 'G',
    symbol: 'G',
    nameTr: 'Sol majör',
    frets: [3, 2, 0, 0, 0, 3],
    fingers: [2, 1, 0, 0, 0, 3],
    tip: 'Altı tel çalınır; parmakların arası geniş, ilk başta zor gelir.',
  );
  static const e7 = ChordShape(
    id: 'E7',
    symbol: 'E7',
    nameTr: 'Mi yedili',
    frets: [0, 2, 0, 1, 0, 0],
    fingers: [0, 2, 0, 1, 0, 0],
    tip: 'E akorundan 3. teldeki parmağı kaldır: blues sesi.',
  );
  static const a7 = ChordShape(
    id: 'A7',
    symbol: 'A7',
    nameTr: 'La yedili',
    frets: [-1, 0, 2, 0, 2, 0],
    fingers: [0, 0, 1, 0, 2, 0],
    tip: 'A akorundan 3. teldeki parmağı kaldır.',
  );
  static const d7 = ChordShape(
    id: 'D7',
    symbol: 'D7',
    nameTr: 'Re yedili',
    frets: [-1, -1, 0, 2, 1, 2],
    fingers: [0, 0, 0, 2, 1, 3],
    tip: 'Üç parmak küçük bir üçgen çizer; sadece alt 4 tel.',
  );
  static const am7 = ChordShape(
    id: 'Am7',
    symbol: 'Am7',
    nameTr: 'La minör yedili',
    frets: [-1, 0, 2, 0, 1, 0],
    fingers: [0, 0, 2, 0, 1, 0],
    tip: 'Am akorundan 3. teldeki parmağı kaldır: yumuşak, kadife ses.',
  );
  static const em7 = ChordShape(
    id: 'Em7',
    symbol: 'Em7',
    nameTr: 'Mi minör yedili',
    frets: [0, 2, 0, 0, 0, 0],
    fingers: [0, 2, 0, 0, 0, 0],
    tip: 'Tek parmak: 5. telin 2. perdesi.',
  );
  static const asus2 = ChordShape(
    id: 'Asus2',
    symbol: 'Asus2',
    nameTr: 'La sus2',
    frets: [-1, 0, 2, 2, 0, 0],
    fingers: [0, 0, 1, 2, 0, 0],
    tip: 'A akorundan 2. tel parmağını kaldır: açık, çan gibi tını.',
  );
  static const dsus2 = ChordShape(
    id: 'Dsus2',
    symbol: 'Dsus2',
    nameTr: 'Re sus2',
    frets: [-1, -1, 0, 2, 3, 0],
    fingers: [0, 0, 0, 1, 2, 0],
    tip: 'D akorundan en ince telin parmağını kaldır.',
  );

  static const all = <ChordShape>[
    d, a, e, em, am, dm, c, g, e7, a7, d7, am7, em7, asus2, dsus2,
  ];

  static ChordShape byId(String id) =>
      all.firstWhere((c) => c.id == id, orElse: () => em);
}
