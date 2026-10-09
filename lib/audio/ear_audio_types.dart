// ignore_for_file: constant_identifier_names

enum EarIntervalType {
  minor2(1, 'Küçük 2\'li (m2)', 'interval_minor2', '1 yarım ses • Gergin, sürtünen adım'),
  major2(2, 'Büyük 2\'li (M2)', 'interval_major2', '2 yarım ses • Gamda sıradan bir adım'),
  minor3(3, 'Küçük 3\'lü (m3)', 'interval_minor3', '3 yarım ses • Melankolik & hüzünlü'),
  major3(4, 'Büyük 3\'lü (M3)', 'interval_major3', '4 yarım ses • Açık & güneşli'),
  perfect4(5, 'Tam 4\'lü (P4)', 'interval_perfect4', '5 yarım ses • İstiklal Marşı açılışı ("Kork-ma")'),
  perfect5(7, 'Tam 5\'li (P5)', 'interval_perfect5', '7 yarım ses • Güçlü & kararlı'),
  octave(12, 'Oktav (P8)', 'interval_octave', '12 yarım ses • Aynı sesin tizi');

  const EarIntervalType(this.semitones, this.label, this.srsKey, this.subtitle);
  final int semitones;
  final String label;
  final String srsKey;
  final String subtitle;

  static EarIntervalType? fromSrsKey(String key) {
    for (final v in values) {
      if (v.srsKey == key) return v;
    }
    return null;
  }
}

enum EarChordQuality {
  major('Majör', 'chord_major', '1 - 3 - 5 • Aydınlık & güneşli'),
  minor('Minör', 'chord_minor', '1 - ♭3 - 5 • Hüzünlü & melankolik'),
  sus2('Sus2 / Add9', 'chord_sus2', '1 - 2 - 5 • Açık, akustik çan'),
  power('Power Chord', 'chord_power', '1 - 5 • Saf güç / distorsiyon'),
  dominant7('Dominant 7', 'chord_dominant7', '1 - 3 - 5 - ♭7 • Blues gerilimi'),
  minor7('Minör 7', 'chord_minor7', '1 - ♭3 - 5 - ♭7 • Kadife akustik hüzün');

  const EarChordQuality(this.label, this.srsKey, this.subtitle);
  final String label;
  final String srsKey;
  final String subtitle;

  /// Kökten yarım ses aralıkları (gitar voicing'i için oktav eklenmiş).
  List<int> get voicing => switch (this) {
        EarChordQuality.major => const [0, 4, 7, 12],
        EarChordQuality.minor => const [0, 3, 7, 12],
        EarChordQuality.sus2 => const [0, 2, 7, 12],
        EarChordQuality.power => const [0, 7, 12],
        EarChordQuality.dominant7 => const [0, 4, 7, 10],
        EarChordQuality.minor7 => const [0, 3, 7, 10],
      };

  static EarChordQuality? fromSrsKey(String key) {
    for (final v in values) {
      if (v.srsKey == key) return v;
    }
    return null;
  }
}

enum EarCadenceType {
  I_IV('I → IV (Yükseliş)', 'cadence_I_IV', 'C → F • Parlak açılış ve genişleme'),
  I_V('I → V (Gerilim)', 'cadence_I_V', 'C → G • Çözülmek isteyen dominant'),
  i_VI('i → VI (Hüzünlü Çöküş)', 'cadence_i_VI', 'Am → F • Duygusal Anadolu minör çöküşü'),
  V7_i('V7 → i (Majör V Çözülüşü)', 'cadence_V7_i', 'E7 → Am • Harmonik minörün karara çekilişi'),
  I_V_vi_IV('I → V → vi → IV (Pop 4 Akor)', 'cadence_pop4', 'C → G → Am → F • Pop hitlerinin omurgası'),
  V_vi('V → vi (Yanıltıcı Kadans)', 'cadence_V_vi', 'G → Am • Beklenen çözülme yerine sürpriz'),
  IV_I('IV → I (Plagal / Amin Kadansı)', 'cadence_IV_I', 'F → C • Kilise ilahilerinin yumuşak "amin" kapanışı');

  const EarCadenceType(this.label, this.srsKey, this.subtitle);
  final String label;
  final String srsKey;
  final String subtitle;

  /// Her akor: kökten yarım ses aralıkları.
  List<List<int>> get chords => switch (this) {
        EarCadenceType.I_IV => const [
            [0, 4, 7, 12],
            [5, 9, 12, 17],
          ],
        EarCadenceType.I_V => const [
            [0, 4, 7, 12],
            [7, 11, 14, 19],
          ],
        EarCadenceType.i_VI => const [
            [0, 3, 7, 12],
            [8, 12, 15, 20],
          ],
        EarCadenceType.V7_i => const [
            [7, 11, 14, 17],
            [0, 3, 7, 12],
          ],
        EarCadenceType.I_V_vi_IV => const [
            [0, 4, 7, 12],
            [7, 11, 14, 19],
            [9, 12, 16, 21],
            [5, 9, 12, 17],
          ],
        EarCadenceType.V_vi => const [
            [7, 11, 14, 19],
            [9, 12, 16, 21],
          ],
        EarCadenceType.IV_I => const [
            [5, 9, 12, 17],
            [0, 4, 7, 12],
          ],
      };

  static EarCadenceType? fromSrsKey(String key) {
    for (final v in values) {
      if (v.srsKey == key) return v;
    }
    return null;
  }
}
