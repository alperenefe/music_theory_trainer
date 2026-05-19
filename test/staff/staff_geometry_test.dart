import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';
import 'package:music_theory_trainer/staff/staff_geometry.dart';

void main() {
  group('StaffGeometry', () {
    test('nearestSlotForY en yakın slot', () {
      const size = Size(400, 300);
      final g = StaffGeometry(size);
      final slots = NotationPitch.allStaffSlots();
      final yE = g.yForSlot(0);
      final yF = g.yForSlot(1);
      expect(g.nearestSlotForY(yE, slots), 0);
      expect(g.nearestSlotForY(yF, slots), 1);
      expect(g.nearestSlotForY(yF - 0.01, slots), 1);
    });

    test('eşitlik boyut ve slot aralığına göre', () {
      final a = StaffGeometry(const Size(100, 200));
      final b = StaffGeometry(const Size(100, 200));
      final c = StaffGeometry(const Size(101, 200));
      final d = StaffGeometry(const Size(100, 200), slotMin: -4, slotMax: 8);
      expect(a == b, isTrue);
      expect(a == c, isFalse);
      expect(a == d, isFalse);
    });

    test('uç slotlar dikey alana sığar', () {
      final slots = NotationPitch.allStaffSlots()..sort();
      final g = StaffGeometry(
        const Size(300, 220),
        slotMin: slots.first,
        slotMax: slots.last,
      );
      final yHigh = g.yForSlot(slots.last);
      final yLow = g.yForSlot(slots.first);
      expect(yHigh, greaterThanOrEqualTo(12));
      expect(yLow, lessThanOrEqualTo(208));
      expect(yHigh, lessThan(yLow));
    });
  });
}
