import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/staff_exercise_range.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';
import 'package:music_theory_trainer/staff/staff_geometry.dart';

void main() {
  test('forExercisePool 5 ana çizgi, kalın Mi altta ince Mi üstte', () {
    final pool = NotationPitch.poolForMidiRange(
      StaffExerciseRange.minMidi,
      StaffExerciseRange.maxMidi,
    );
    final slots = pool.map((e) => e.staffSlot).toList()..sort();
    const h = 400.0;
    final g = StaffGeometry.forExercisePool(
      const Size(300, h),
      poolSlotMin: slots.first,
      poolSlotMax: slots.last,
    );
    expect(g.slotMax, greaterThanOrEqualTo(8));
    expect(g.mainLineYs().length, 5);

    final low = pool.firstWhere((p) => p.midi == 40);
    final openHigh = pool.firstWhere((p) => p.midi == 64);
    final la5 = pool.firstWhere((p) => p.midi == 69);

    final yMi2 = g.yForSlot(low.staffSlot);
    final yInceMi = g.yForSlot(openHigh.staffSlot);
    final yLa = g.yForSlot(la5.staffSlot);
    final yTop = g.yForSlot(8);

    expect(yMi2, greaterThan(yInceMi));
    expect(yInceMi, greaterThan(yLa));
    expect(yLa, lessThan(yTop));
    expect(yMi2, lessThan(h - 4));
    expect(yTop, greaterThan(4));
  });

  test('porte altı: çizgi–aralık–çizgi eşit dikey adım', () {
    final pool = NotationPitch.poolForMidiRange(40, 69);
    final slots = pool.map((e) => e.staffSlot).toList()..sort();
    final g = StaffGeometry.forExercisePool(
      const Size(300, 400),
      poolSlotMin: slots.first,
      poolSlotMax: slots.last,
    );
    final d01 = (g.yForSlot(-1) - g.yForSlot(0)).abs();
    final d12 = (g.yForSlot(-2) - g.yForSlot(-1)).abs();
    expect(d01, closeTo(d12, 0.5));
    expect(g.yForSlot(-2), greaterThan(g.yForSlot(0)));
    expect(g.yForSlot(-4), greaterThan(g.yForSlot(-2)));
  });

  test('G teli 2. perde La3 yazım slotu 3', () {
    expect(NotationPitch.staffSlotForSoundingMidi(57), 3);
  });

  test('kalın Mi slot -7, ince Mi açık üst aralık slot 7', () {
    expect(NotationPitch.staffSlotForSoundingMidi(40), -7);
    expect(NotationPitch.staffSlotForSoundingMidi(64), 7);
  });

  test('Do (3. oktav) yazımda porte altı çizgi slot -2', () {
    expect(NotationPitch.staffSlotForSoundingMidi(48), -2);
    expect((-2).isEven, isTrue);
  });
}
