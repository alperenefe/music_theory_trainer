import 'dart:math';

import '../theory/theory_note_labels.dart';

final class GuitarNote {
  const GuitarNote({required this.string, required this.fret});

  final int string;
  final int fret;

  // string 0 = high E (MIDI 64), string 5 = low E (MIDI 40)
  static const _openMidi = [64, 59, 55, 50, 45, 40];
  static const _openName = ['Mi', 'Si', 'Sol', 'Re', 'La', 'Mi'];
  static const _stringLabel = ['e', 'B', 'G', 'D', 'A', 'E'];

  int get midi => _openMidi[string] + fret;

  int get pitchClass => midi % 12;

  String get noteName =>
      TheoryNoteLabels.label(midi, withOctave: false);

  String get stringLabel => _stringLabel[string];

  String get openStringName => _openName[string];

  /// Örn. «Sol teli · 2. perde» (tel adı = boş teldeki nota).
  String get positionLabel => '$openStringName teli · $fret. perde';

  double get frequency => 440.0 * pow(2.0, (midi - 69) / 12.0);

  static String noteNameForMidi(int midi) =>
      TheoryNoteLabels.label(midi, withOctave: false);

  static List<GuitarNote> allNotes({int minFret = 0, int maxFret = 7}) {
    final out = <GuitarNote>[];
    for (var s = 0; s < 6; s++) {
      for (var f = minFret; f <= maxFret; f++) {
        out.add(GuitarNote(string: s, fret: f));
      }
    }
    return out;
  }

  static List<GuitarNote> notesWithMidi(
    int midi, {
    int minFret = 0,
    int maxFret = 7,
  }) {
    return allNotes(
      minFret: minFret,
      maxFret: maxFret,
    ).where((n) => n.midi == midi).toList();
  }

  static List<String> mcqOptionsForMidi(
    int correctMidi,
    List<GuitarNote> pool,
    Random rnd,
  ) {
    return mcqOptions(
      TheoryNoteLabels.label(correctMidi, withOctave: false),
      pool,
      rnd,
    );
  }

  static List<String> mcqOptions(
    String correct,
    List<GuitarNote> pool,
    Random rnd,
  ) {
    final opts = <String>{correct};
    final candidates =
        pool.map((e) => e.noteName).where((n) => n != correct).toSet().toList()
          ..shuffle(rnd);
    for (final c in candidates) {
      if (opts.length >= 4) break;
      opts.add(c);
    }
    const fallback = TheoryNoteLabels.chromaticPalette;
    var fi = 0;
    while (opts.length < 4 && fi < fallback.length) {
      final n = fallback[fi++];
      if (!opts.contains(n)) {
        opts.add(n);
      }
    }
    final list = opts.toList()..shuffle(rnd);
    return list;
  }

  static bool samePitchClass(int a, int b) => a % 12 == b % 12;

  @override
  bool operator ==(Object other) =>
      other is GuitarNote && other.string == string && other.fret == fret;

  @override
  int get hashCode => Object.hash(string, fret);
}
