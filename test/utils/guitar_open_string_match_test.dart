import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/utils/guitar_open_string_match.dart';

void main() {
  test('110 Hz La teli (A2)', () {
    final r = GuitarOpenStringMatch.bestForHz(110, 440);
    expect(r.stringIndex, 4);
    expect(r.targetMidi, 45);
  });

  test('82 Hz kalın Mi (E2)', () {
    final r = GuitarOpenStringMatch.bestForHz(82.41, 440);
    expect(r.stringIndex, 5);
    expect(r.targetMidi, 40);
  });

  test('164 Hz harmonik E3 kalın tel', () {
    final r = GuitarOpenStringMatch.bestForHz(164.8, 440);
    expect(r.stringIndex, 5);
    expect(r.targetMidi, 52);
  });

  test('330 Hz ince Mi (E4)', () {
    final r = GuitarOpenStringMatch.bestForHz(329.63, 440);
    expect(r.stringIndex, 0);
    expect(r.targetMidi, 64);
  });

  test('bestForHzOnString sadece o telin oktavları', () {
    final r = GuitarOpenStringMatch.bestForHzOnString(164.8, 440, 5);
    expect(r.stringIndex, 5);
    expect(r.targetMidi, 52);
  });
}
