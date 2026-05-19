import '../models/notation_pitch.dart';

/// Türkçe nota adı (diyez ve bemol).
abstract final class TheoryNoteLabels {
  static const List<String> _chromaticSharp = [
    'Do',
    'Do diyez',
    'Re',
    'Re diyez',
    'Mi',
    'Fa',
    'Fa diyez',
    'Sol',
    'Sol diyez',
    'La',
    'La diyez',
    'Si',
  ];

  /// Ekranda gösterilen tüm adlar (sırayla dokunma paleti).
  static const List<String> chromaticPalette = [
    'Do',
    'Do diyez',
    'Re bemol',
    'Re',
    'Re diyez',
    'Mi bemol',
    'Mi',
    'Fa',
    'Fa diyez',
    'Sol bemol',
    'Sol',
    'Sol diyez',
    'La bemol',
    'La',
    'La diyez',
    'Si bemol',
    'Si',
  ];

  static const Map<String, int> _pitchClassByLabel = {
    'Do': 0,
    'Do diyez': 1,
    'Re bemol': 1,
    'Re': 2,
    'Re diyez': 3,
    'Mi bemol': 3,
    'Mi': 4,
    'Fa': 5,
    'Fa diyez': 6,
    'Sol bemol': 6,
    'Sol': 7,
    'Sol diyez': 8,
    'La bemol': 8,
    'La': 9,
    'La diyez': 10,
    'Si bemol': 10,
    'Si': 11,
  };

  static int? pitchClassForLabel(String label) => _pitchClassByLabel[label];

  static String label(int midi, {bool withOctave = true}) {
    final name = _chromaticSharp[midi % 12];
    if (!withOctave) {
      return name;
    }
    return '$name (${NotationPitch.octaveNumber(midi)}. oktav)';
  }

  static List<String> optionLabels(
    Iterable<int> midis, {
    bool withOctave = true,
  }) {
    return midis.map((m) => label(m, withOctave: withOctave)).toList();
  }
}
