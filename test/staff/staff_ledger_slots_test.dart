import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/staff_exercise_range.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';
import 'package:music_theory_trainer/staff/staff_ledger_slots.dart';

void main() {
  test('gitar porte aralığı uçları doğru slot', () {
    final pool = NotationPitch.poolForMidiRange(
      StaffExerciseRange.minMidi,
      StaffExerciseRange.maxMidi,
    );
    final low = pool.firstWhere((p) => p.midi == StaffExerciseRange.minMidi);
    final high = pool.firstWhere((p) => p.midi == StaffExerciseRange.maxMidi);
    expect(low.staffSlot, -7);
    expect(high.staffSlot, 11);
  });

  test('ince Mi açık üst aralık slot 7', () {
    expect(NotationPitch.staffSlotForSoundingMidi(64), 7);
    expect(NotationPitch.midiAtSlot(7), 64);
  });

  test('1. tel 5. perde La ve 7. perde Si porte slotları', () {
    expect(NotationPitch.staffSlotForSoundingMidi(69), 10);
    expect(NotationPitch.staffSlotForSoundingMidi(71), 11);
  });

  test('yardımcı çizgi yalnızca çizgi slotlarında, aralıkta değil', () {
    final pool = NotationPitch.poolForMidiRange(
      StaffExerciseRange.minMidi,
      StaffExerciseRange.maxMidi,
    );
    final slots = pool.map((e) => e.staffSlot).toList();
    final ledgers = StaffLedgerSlots.forExerciseRange(slots);
    expect(ledgers, contains(-6));
    expect(ledgers, contains(10));
    expect(ledgers.contains(-13), isFalse);
    expect(ledgers.contains(-11), isFalse);
  });
}
