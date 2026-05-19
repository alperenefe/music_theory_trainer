import 'dart:math';

import 'theory_note_labels.dart';

enum ChordQuality { major, minor }

abstract final class MusicChord {
  static String qualityName(ChordQuality q) =>
      q == ChordQuality.major ? 'majör' : 'minör';

  static List<int> triad(int rootMidi, ChordQuality q) {
    final third = q == ChordQuality.major ? 4 : 3;
    return [rootMidi, rootMidi + third, rootMidi + 7];
  }

  static String chordSymbol(int rootMidi, ChordQuality q) {
    final root = TheoryNoteLabels.label(rootMidi, withOctave: false);
    if (q == ChordQuality.minor) {
      return '${root}m';
    }
    return root;
  }

  static String notesJoined(List<int> notes) {
    return notes
        .map((m) => TheoryNoteLabels.label(m, withOctave: true))
        .join(' · ');
  }

  static String buildNotesQuestion(int rootMidi, ChordQuality q) {
    return '${chordSymbol(rootMidi, q)} akoru hangi notalardan?';
  }

  static String buildNameQuestion(List<int> notes) {
    return '${notesJoined(notes)} → hangi akor?';
  }

  static List<String> buildNoteSetOptions({
    required List<int> correct,
    required int minMidi,
    required int maxMidi,
    required Random rnd,
  }) {
    final correctLabel = notesJoined(correct);
    final wrong = <String>{};
    while (wrong.length < 3) {
      final r = minMidi + rnd.nextInt(max(1, maxMidi - minMidi + 1));
      final q = rnd.nextBool() ? ChordQuality.major : ChordQuality.minor;
      final label = notesJoined(triad(r, q));
      if (label != correctLabel) {
        wrong.add(label);
      }
    }
    return [correctLabel, ...wrong]..shuffle(rnd);
  }

  static List<String> buildNameOptions({
    required String correct,
    required int rootMidi,
    required Random rnd,
  }) {
    final wrong = <String>{};
    while (wrong.length < 3) {
      final altRoot = rootMidi + [-2, 2, 3, 5, 7][rnd.nextInt(5)];
      final q = rnd.nextBool() ? ChordQuality.major : ChordQuality.minor;
      final s = chordSymbol(altRoot, q);
      if (s != correct) {
        wrong.add(s);
      }
    }
    return [correct, ...wrong]..shuffle(rnd);
  }
}
