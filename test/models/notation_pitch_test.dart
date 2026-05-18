import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';

void main() {
  setUpAll(() {
    NotationPitch.resetSharedPool();
  });

  group('NotationPitch', () {
    test('trainingPool doğal notalar ve aralıkta', () {
      final pool = NotationPitch.trainingPool();
      final midis = pool.map((e) => e.midi).toList();
      expect(midis.toSet().length, midis.length);
      for (final p in pool) {
        expect(p.midi, greaterThanOrEqualTo(40));
        expect(p.midi, lessThanOrEqualTo(84));
      }
    });

    test('midiAtSlot genişletilmiş perdeler', () {
      expect(NotationPitch.midiAtSlot(-14), 40);
      expect(NotationPitch.midiAtSlot(-3), 59);
    });

    test('midiAtSlot doğal perde', () {
      expect(NotationPitch.midiAtSlot(0), 64);
      expect(NotationPitch.midiAtSlot(1), 65);
      expect(NotationPitch.midiAtSlot(-2), 60);
    });

    test('sharedPool önbellekli aynı örnek', () {
      NotationPitch.resetSharedPool();
      final a = NotationPitch.sharedPool();
      final b = NotationPitch.sharedPool();
      expect(identical(a, b), isTrue);
    });

    test('displayForMidi havuzda bulur', () {
      final pool = NotationPitch.trainingPool();
      final p = pool.firstWhere((e) => e.midi == 72);
      expect(NotationPitch.displayForMidi(72, pool), p.displayTurkish);
    });

    test('poolForMidiRange süzgeç', () {
      final narrow = NotationPitch.poolForMidiRange(60, 72);
      for (final p in narrow) {
        expect(p.midi, greaterThanOrEqualTo(60));
        expect(p.midi, lessThanOrEqualTo(72));
      }
      final swapped = NotationPitch.poolForMidiRange(72, 60);
      expect(swapped.length, narrow.length);
    });

    test('allStaffSlots artan sırada', () {
      final s = NotationPitch.allStaffSlots();
      expect(s, isNotEmpty);
      for (var i = 0; i < s.length - 1; i++) {
        expect(s[i], lessThan(s[i + 1]));
      }
    });
  });
}
