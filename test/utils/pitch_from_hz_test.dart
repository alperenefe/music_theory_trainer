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

    test('octaveNestForGuitar yarım frekansı yukarı iter', () {
      expect(PitchFromHz.octaveNestForGuitar(41), closeTo(82, 0.01));
      expect(PitchFromHz.octaveNestForGuitar(82), closeTo(82, 0.01));
      expect(PitchFromHz.midiFromHz(PitchFromHz.octaveNestForGuitar(41)), 40);
    });
  });
}
