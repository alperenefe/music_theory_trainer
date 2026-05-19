import 'theory_note_labels.dart';

enum ScaleMode { major, naturalMinor }

/// Bir gam derecesinin doğru yazımı (MIDI + etiket).
final class ScaleDegree {
  const ScaleDegree({required this.midi, required this.label});

  final int midi;
  final String label;
}

abstract final class MusicScale {
  static const List<int> majorSteps = [2, 2, 1, 2, 2, 2, 1];
  static const List<int> minorSteps = [2, 1, 2, 2, 1, 2, 2];

  static String modeName(ScaleMode m) =>
      m == ScaleMode.major ? 'majör' : 'doğal minör';

  static List<int> degrees(int rootMidi, ScaleMode mode) {
    final steps = mode == ScaleMode.major ? majorSteps : minorSteps;
    final out = <int>[rootMidi];
    var cur = rootMidi;
    for (final s in steps) {
      cur += s;
      out.add(cur);
    }
    return out;
  }

  /// Kök perde sınıfına göre majör gam yazımı (7 ad).
  static const Map<int, List<String>> _majorSpellingsByPc = {
    0: ['Do', 'Re', 'Mi', 'Fa', 'Sol', 'La', 'Si'],
    1: [
      'Re bemol',
      'Mi bemol',
      'Fa',
      'Sol',
      'La bemol',
      'Si bemol',
      'Do',
    ],
    2: ['Re', 'Mi', 'Fa diyez', 'Sol', 'La', 'Si', 'Do diyez'],
    3: ['Mi bemol', 'Fa', 'Sol', 'La bemol', 'Si bemol', 'Do', 'Re'],
    4: ['Mi', 'Fa diyez', 'Sol diyez', 'La', 'Si', 'Do diyez', 'Re diyez'],
    5: ['Fa', 'Sol', 'La', 'Si bemol', 'Do', 'Re', 'Mi'],
    6: [
      'Fa diyez',
      'Sol diyez',
      'La diyez',
      'Si',
      'Do diyez',
      'Re diyez',
      'Mi diyez',
    ],
    7: ['Sol', 'La', 'Si', 'Do', 'Re', 'Mi', 'Fa diyez'],
    8: ['La bemol', 'Si bemol', 'Do', 'Re bemol', 'Mi bemol', 'Fa', 'Sol'],
    9: ['La', 'Si', 'Do diyez', 'Re', 'Mi', 'Fa diyez', 'Sol diyez'],
    10: ['Si bemol', 'Do', 'Re', 'Mi', 'Fa', 'Sol', 'La'],
    11: [
      'Si',
      'Do diyez',
      'Re diyez',
      'Mi',
      'Fa diyez',
      'Sol diyez',
      'La diyez',
    ],
  };

  static List<String> spelledLabels(int rootMidi, ScaleMode mode) {
    final pc = rootMidi % 12;
    if (mode == ScaleMode.major) {
      return List<String>.from(_majorSpellingsByPc[pc]!);
    }
    final relPc = (pc + 3) % 12;
    final rel = _majorSpellingsByPc[relPc]!;
    final i = rel.indexWhere(
      (name) => TheoryNoteLabels.pitchClassForLabel(name) == pc,
    );
    if (i < 0) {
      return List<String>.from(_majorSpellingsByPc[pc]!);
    }
    return [...rel.sublist(i), ...rel.sublist(0, i)];
  }

  static List<ScaleDegree> spelledDegrees(int rootMidi, ScaleMode mode) {
    final midis = degrees(rootMidi, mode);
    final names = spelledLabels(rootMidi, mode);
    return [
      for (var i = 0; i < names.length; i++)
        ScaleDegree(midi: midis[i], label: names[i]),
    ];
  }

  static String fullScalePrompt(int rootMidi, ScaleMode mode) {
    final root = TheoryNoteLabels.label(rootMidi, withOctave: false);
    return '$root ${modeName(mode)} gamını sırayla kur';
  }

  static String stepHint(int step, int total) => '${step + 1}/$total. nota';
}
