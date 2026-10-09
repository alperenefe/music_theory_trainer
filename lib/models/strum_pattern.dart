/// Bir ölçüdeki (4/4) sekizlik dilimlerden birinde ne çalınır.
enum StrumSlot { down, up, rest }

/// 4/4'lük bir ölçü için vuruş kalıbı: 8 sekizlik dilim (1, 1+, 2, 2+ … 4, 4+).
final class StrumPattern {
  const StrumPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.slots,
    this.minBpm = 50,
    this.maxBpm = 110,
  });

  final String id;
  final String name;
  final String description;
  final List<StrumSlot> slots;

  /// Algılayıcının güvenilir çalıştığı tempo aralığı: sekizliklerde (273 ms)
  /// üst sınır ≈ 110 BPM (bkz. test/dsp/rhythm_test.dart).
  final int minBpm;
  final int maxBpm;

  static const eighthLabels = ['1', '+', '2', '+', '3', '+', '4', '+'];

  /// Zorunlu (aşağı) vuruşların ölçü içindeki sekizlik dilim sırası.
  List<int> get downSlots => [
        for (var i = 0; i < 8; i++)
          if (slots[i] == StrumSlot.down) i,
      ];

  /// İsteğe bağlı (yukarı) vuruşların dilim sırası.
  List<int> get upSlots => [
        for (var i = 0; i < 8; i++)
          if (slots[i] == StrumSlot.up) i,
      ];

  bool get hasUps => slots.contains(StrumSlot.up);
}

abstract final class StrumPatterns {
  static const quarters = StrumPattern(
    id: 'quarters',
    name: 'Dört aşağı vuruş',
    description: 'Her vuruşta bir aşağı vuruş: 1 – 2 – 3 – 4. Başlangıç için en sağlam temel.',
    slots: [
      StrumSlot.down, StrumSlot.rest, StrumSlot.down, StrumSlot.rest,
      StrumSlot.down, StrumSlot.rest, StrumSlot.down, StrumSlot.rest,
    ],
    minBpm: 50,
    maxBpm: 130,
  );

  static const eighths = StrumPattern(
    id: 'eighths',
    name: 'Aşağı-yukarı sekizlik',
    description: 'Ele sürekli sallanan bir sarkaç gibi bak: vuruşlarda aşağı, aralarda yukarı.',
    slots: [
      StrumSlot.down, StrumSlot.up, StrumSlot.down, StrumSlot.up,
      StrumSlot.down, StrumSlot.up, StrumSlot.down, StrumSlot.up,
    ],
  );

  /// JustinGuitar "THE strumming pattern": 1 2+ +4 → D, D U, (atla), U, D.
  static const classic = StrumPattern(
    id: 'classic',
    name: 'Klasik kalıp',
    description:
        '3. vuruşun aşağı vuruşu atlanır ama elin hareketi durmaz (sarkaç gibi). Sayarak çal: 1  2+  +  4.',
    slots: [
      StrumSlot.down, StrumSlot.rest, StrumSlot.down, StrumSlot.up,
      StrumSlot.rest, StrumSlot.up, StrumSlot.down, StrumSlot.rest,
    ],
  );

  /// Pop ve folk'ta en yaygın kalıp: D  D U  U D U.
  static const universal = StrumPattern(
    id: 'universal',
    name: 'Evrensel kalıp',
    description: 'Yüzlerce şarkıda çalan kalıp: aşağı, aşağı-yukarı, yukarı, aşağı-yukarı.',
    slots: [
      StrumSlot.down, StrumSlot.rest, StrumSlot.down, StrumSlot.up,
      StrumSlot.rest, StrumSlot.up, StrumSlot.down, StrumSlot.up,
    ],
  );

  static const all = [quarters, eighths, classic, universal];

  static StrumPattern byId(String id) =>
      all.firstWhere((p) => p.id == id, orElse: () => quarters);
}
