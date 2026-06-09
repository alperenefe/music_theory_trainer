import 'theory_note_labels.dart';

enum IntervalKind {
  minorSecond,
  majorSecond,
  minorThird,
  majorThird,
  perfectFourth,
  tritone,
  perfectFifth,
  minorSixth,
  majorSixth,
  minorSeventh,
  majorSeventh,
  octave,
}

abstract final class MusicInterval {
  static const Map<IntervalKind, int> semitones = {
    IntervalKind.minorSecond: 1,
    IntervalKind.majorSecond: 2,
    IntervalKind.minorThird: 3,
    IntervalKind.majorThird: 4,
    IntervalKind.perfectFourth: 5,
    IntervalKind.tritone: 6,
    IntervalKind.perfectFifth: 7,
    IntervalKind.minorSixth: 8,
    IntervalKind.majorSixth: 9,
    IntervalKind.minorSeventh: 10,
    IntervalKind.majorSeventh: 11,
    IntervalKind.octave: 12,
  };

  static String turkishName(IntervalKind k) => switch (k) {
        IntervalKind.minorSecond => 'küçük 2li',
        IntervalKind.majorSecond => 'büyük 2li',
        IntervalKind.minorThird => 'küçük 3lü',
        IntervalKind.majorThird => 'büyük 3lü',
        IntervalKind.perfectFourth => 'tam 4lü',
        IntervalKind.tritone => 'tritonus',
        IntervalKind.perfectFifth => 'tam 5li',
        IntervalKind.minorSixth => 'küçük 6lı',
        IntervalKind.majorSixth => 'büyük 6lı',
        IntervalKind.minorSeventh => 'küçük 7li',
        IntervalKind.majorSeventh => 'büyük 7li',
        IntervalKind.octave => 'oktav',
      };

  static String directionWord(bool up) => up ? 'yukarı' : 'aşağı';

  static int apply(int rootMidi, IntervalKind kind, {required bool up}) {
    final delta = semitones[kind]! * (up ? 1 : -1);
    return rootMidi + delta;
  }

  static IntervalKind? between(int fromMidi, int toMidi) {
    final d = (toMidi - fromMidi).abs() % 12;
    for (final e in IntervalKind.values) {
      if (semitones[e] == d) {
        return e;
      }
    }
    return null;
  }

  /// Oktav hariç tam aralık seti (ZIP INTERVALS_TURKISH ile uyumlu).
  static const List<IntervalKind> practiceSet = [
    IntervalKind.minorSecond,
    IntervalKind.majorSecond,
    IntervalKind.minorThird,
    IntervalKind.majorThird,
    IntervalKind.perfectFourth,
    IntervalKind.tritone,
    IntervalKind.perfectFifth,
    IntervalKind.minorSixth,
    IntervalKind.majorSixth,
    IntervalKind.minorSeventh,
    IntervalKind.majorSeventh,
  ];

  static int clampMidi(int m, int lo, int hi) => m.clamp(lo, hi);

  static String buildQuestionText({
    required int rootMidi,
    required IntervalKind kind,
    required bool up,
  }) {
    final root = TheoryNoteLabels.label(rootMidi, withOctave: false);
    final dir = directionWord(up);
    final interval = turkishName(kind);
    return "$root'un $dir $interval hangi notadır?";
  }
}
