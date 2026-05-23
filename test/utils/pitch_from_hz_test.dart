import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/utils/pitch_from_hz.dart';

void main() {
  group('PitchFromHz', () {
    test('A4 yakını MIDI 69', () {
      expect(PitchFromHz.midiFromHz(440), 69);
    });

    test('çok düşük veya yüksek null', () {
      expect(PitchFromHz.midiFromHz(40), isNull);
      expect(PitchFromHz.midiFromHz(600), isNull);
    });

    test('A4 referansı 432 ile A4 frekansı MIDI 69', () {
      expect(PitchFromHz.midiFromHz(432, referenceA4: 432), 69);
    });

    test('refineForGuitar düşük frekansı oktava taşır', () {
      expect(PitchFromHz.refineForGuitar(41), closeTo(82.41, 0.5));
      expect(PitchFromHz.refineForGuitar(82), closeTo(82.41, 0.5));
      expect(PitchFromHz.midiFromHz(PitchFromHz.refineForGuitar(41)), 40);
    });
  });
}
