import '../models/guitar_note.dart';
import 'pitch_from_hz.dart';

typedef GuitarOpenStringMatchResult = ({
  int stringIndex,
  int targetMidi,
  double targetHz,
});

abstract final class GuitarOpenStringMatch {
  static const int _minMidi = 28;
  static const int _maxMidi = 90;

  static GuitarOpenStringMatchResult bestForHz(
    double hz,
    double referenceA4,
  ) {
    var bestString = 5;
    var bestScore = double.infinity;
    var bestMidi = 40;
    var bestHz = PitchFromHz.hzFromMidi(40, referenceA4);
    var bestOpenMidi = 40;
    const tieCents = 0.05;
    for (var s = 5; s >= 0; s--) {
      final m0 = GuitarNote(string: s, fret: 0).midi;
      for (var k = -2; k <= 4; k++) {
        final m = m0 + 12 * k;
        if (m < _minMidi || m > _maxMidi) {
          continue;
        }
        final tHz = PitchFromHz.hzFromMidi(m, referenceA4);
        if (tHz < 70 || tHz > 520) {
          continue;
        }
        final c = PitchFromHz.centsDelta(hz, tHz);
        if (c == null) {
          continue;
        }
        final score = c.abs();
        final span = (m - m0).abs();
        final better = score < bestScore - tieCents ||
            ((score - bestScore).abs() <= tieCents &&
                span < (bestMidi - bestOpenMidi).abs());
        if (better) {
          bestScore = score;
          bestString = s;
          bestMidi = m;
          bestHz = tHz;
          bestOpenMidi = m0;
        }
      }
    }
    return (
      stringIndex: bestString,
      targetMidi: bestMidi,
      targetHz: bestHz,
    );
  }

  static GuitarOpenStringMatchResult bestForHzOnString(
    double hz,
    double referenceA4,
    int stringIndex,
  ) {
    var bestMidi = GuitarNote(string: stringIndex, fret: 0).midi;
    var bestHz = PitchFromHz.hzFromMidi(bestMidi, referenceA4);
    var bestScore = double.infinity;
    final m0 = GuitarNote(string: stringIndex, fret: 0).midi;
    for (var k = -2; k <= 4; k++) {
      final m = m0 + 12 * k;
      if (m < _minMidi || m > _maxMidi) {
        continue;
      }
      final tHz = PitchFromHz.hzFromMidi(m, referenceA4);
      if (tHz < 70 || tHz > 520) {
        continue;
      }
      final c = PitchFromHz.centsDelta(hz, tHz);
      if (c == null) {
        continue;
      }
      final score = c.abs();
      if (score < bestScore) {
        bestScore = score;
        bestMidi = m;
        bestHz = tHz;
      }
    }
    return (
      stringIndex: stringIndex,
      targetMidi: bestMidi,
      targetHz: bestHz,
    );
  }
}
