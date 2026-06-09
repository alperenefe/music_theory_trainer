import 'dart:math';

import 'theory_note_labels.dart';

enum ChordQuality {
  major,
  minor,
  diminished,
  augmented,
  dominant7,
}

abstract final class MusicChord {
  static const List<ChordQuality> practiceSet = [
    ChordQuality.major,
    ChordQuality.minor,
    ChordQuality.diminished,
    ChordQuality.augmented,
    ChordQuality.dominant7,
  ];

  static String qualityName(ChordQuality q) => switch (q) {
        ChordQuality.major => 'majör',
        ChordQuality.minor => 'minör',
        ChordQuality.diminished => 'eksilmiş',
        ChordQuality.augmented => 'artık',
        ChordQuality.dominant7 => 'dominant 7li',
      };

  static List<int> chordNotes(int rootMidi, ChordQuality q) => switch (q) {
        ChordQuality.major => [rootMidi, rootMidi + 4, rootMidi + 7],
        ChordQuality.minor => [rootMidi, rootMidi + 3, rootMidi + 7],
        ChordQuality.diminished => [rootMidi, rootMidi + 3, rootMidi + 6],
        ChordQuality.augmented => [rootMidi, rootMidi + 4, rootMidi + 8],
        ChordQuality.dominant7 => [
            rootMidi,
            rootMidi + 4,
            rootMidi + 7,
            rootMidi + 10,
          ],
      };

  /// Geriye uyumluluk.
  static List<int> triad(int rootMidi, ChordQuality q) {
    final notes = chordNotes(rootMidi, q);
    return notes.length <= 3 ? notes : notes.sublist(0, 3);
  }

  static String chordSymbol(int rootMidi, ChordQuality q) {
    final root = TheoryNoteLabels.label(rootMidi, withOctave: false);
    return switch (q) {
      ChordQuality.major => root,
      ChordQuality.minor => '${root}m',
      ChordQuality.diminished => '${root}dim',
      ChordQuality.augmented => '${root}aug',
      ChordQuality.dominant7 => '${root}7',
    };
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

  static ChordQuality randomQuality(Random rnd) =>
      practiceSet[rnd.nextInt(practiceSet.length)];

  static ChordQuality randomPracticeQuality(Random rnd) => randomQuality(rnd);

  static List<String> buildNoteSetOptions({
    required List<int> correct,
    required int minMidi,
    required int maxMidi,
    required Random rnd,
  }) {
    final correctLabel = notesJoined(correct);
    final wrong = <String>{};
    var guard = 0;
    while (wrong.length < 3 && guard < 80) {
      guard++;
      final r = minMidi + rnd.nextInt(max(1, maxMidi - minMidi + 1));
      final q = randomQuality(rnd);
      final label = notesJoined(chordNotes(r, q));
      if (label != correctLabel) {
        wrong.add(label);
      }
    }
    while (wrong.length < 3) {
      wrong.add('$correctLabel?');
    }
    return [correctLabel, ...wrong.take(3)]..shuffle(rnd);
  }

  static List<String> buildNameOptions({
    required String correct,
    required int rootMidi,
    required Random rnd,
  }) {
    final wrong = <String>{};
    var guard = 0;
    while (wrong.length < 3 && guard < 80) {
      guard++;
      final altRoot = rootMidi + [-2, 2, 3, 5, 7][rnd.nextInt(5)];
      final q = randomQuality(rnd);
      final s = chordSymbol(altRoot, q);
      if (s != correct) {
        wrong.add(s);
      }
    }
    while (wrong.length < 3) {
      wrong.add('${correct}x');
    }
    return [correct, ...wrong.take(3)]..shuffle(rnd);
  }
}
