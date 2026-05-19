import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/staff_exercise_range.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';
import 'package:music_theory_trainer/staff/staff_geometry.dart';
import 'package:music_theory_trainer/theme/app_spacing.dart';
import 'package:music_theory_trainer/widgets/exercise/staff_exercise_card.dart';

void main() {
  group('StaffGeometry viewport', () {
    test('1. tel La/Si slotları dar alanda ekran içinde', () {
      final pool = NotationPitch.poolForMidiRange(
        StaffExerciseRange.minMidi,
        StaffExerciseRange.maxMidi,
      );
      final slots = pool.map((e) => e.staffSlot).toList()..sort();
      final g = StaffGeometry.forExercisePool(
        const Size(300, AppSpacing.staffAreaHeight),
        poolSlotMin: slots.first,
        poolSlotMax: slots.last,
      );
      expect(g.slotMax, 11);
      for (final slot in [7, 8, 10, 11]) {
        expect(
          g.slotFitsVertically(slot),
          isTrue,
          reason: 'slot $slot y=${g.yForSlot(slot)} h=${g.size.height}',
        );
      }
    });

    test('placement Expanded yüksekliğinde üst notalar sığar', () {
      final pool = NotationPitch.poolForMidiRange(40, 71);
      final slots = pool.map((e) => e.staffSlot).toList()..sort();
      const phoneStaffH = 280.0;
      final g = StaffGeometry.forExercisePool(
        const Size(360, phoneStaffH),
        poolSlotMin: slots.first,
        poolSlotMax: slots.last,
      );
      final si = pool.firstWhere((p) => p.midi == 71);
      final la = pool.firstWhere((p) => p.midi == 69);
      expect(g.slotFitsVertically(si.staffSlot), isTrue);
      expect(g.slotFitsVertically(la.staffSlot), isTrue);
      expect(g.yForSlot(si.staffSlot), lessThan(g.yForSlot(8)));
    });

    testWidgets('McqStaffCard Si4 porte üstünde layout taşmaz', (tester) async {
      final pool = NotationPitch.poolForMidiRange(64, 71);
      final si = pool.firstWhere((p) => p.midi == 71);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 360,
                height: AppSpacing.mcqStaffAreaHeight,
                child: McqStaffCard(
                  pool: pool,
                  targetStaffSlot: si.staffSlot,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      final g = StaffGeometry.forExercisePool(
        Size(360, AppSpacing.mcqStaffAreaHeight),
        poolSlotMin: -7,
        poolSlotMax: 11,
      );
      expect(g.slotFitsVertically(si.staffSlot), isTrue);
    });
  });
}
