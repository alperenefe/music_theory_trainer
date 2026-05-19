import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/staff_exercise_range.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';

void main() {
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

    test('gitar yazımı: duyulan MIDI → porte slotu', () {
      expect(NotationPitch.staffSlotForSoundingMidi(40), -7);
      expect(NotationPitch.staffSlotForSoundingMidi(64), 7);
      expect(NotationPitch.staffSlotForSoundingMidi(69), 10);
      expect(NotationPitch.staffSlotForSoundingMidi(71), 11);
    });

    test('midiAtSlot duyulan perde döner', () {
      expect(NotationPitch.midiAtSlot(-7), 40);
      expect(NotationPitch.midiAtSlot(7), 64);
      expect(NotationPitch.midiAtSlot(10), 69);
      expect(NotationPitch.midiAtSlot(11), 71);
    });

    test('trainingPool her çağrıda yeni liste', () {
      final a = NotationPitch.trainingPool();
      final b = NotationPitch.trainingPool();
      expect(identical(a, b), isFalse);
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

    test('StaffExerciseRange Si4 dahil', () {
      final pool = NotationPitch.poolForMidiRange(
        StaffExerciseRange.minMidi,
        StaffExerciseRange.maxMidi,
      );
      expect(pool.any((p) => p.midi == 71), isTrue);
      final si = pool.firstWhere((p) => p.midi == 71);
      expect(si.staffSlot, 11);
    });

    test('buildDisplayLabel oktavlı doğal ad', () {
      expect(NotationPitch.buildDisplayLabel(60), 'Do (4. oktav)');
      expect(NotationPitch.buildDisplayLabel(69), 'La (4. oktav)');
      expect(NotationPitch.buildDisplayLabel(64), 'Mi (4. oktav)');
      expect(
        NotationPitch.displayLabelForSlot(7),
        'Mi (4. oktav)',
      );
    });

    test('displayLabelForSlot MIDI ile uyumlu', () {
      for (final slot in NotationPitch.allStaffSlots()) {
        final midi = NotationPitch.midiAtSlot(slot);
        if (midi == null || midi < 40) {
          continue;
        }
        expect(
          NotationPitch.displayLabelForSlot(slot),
          NotationPitch.buildDisplayLabel(midi),
        );
      }
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
