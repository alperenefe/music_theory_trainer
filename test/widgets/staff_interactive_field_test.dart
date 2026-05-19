import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/staff_exercise_range.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';
import 'package:music_theory_trainer/staff/staff_geometry.dart';
import 'package:music_theory_trainer/widgets/exercise/staff_interactive_field.dart';

void main() {
  testWidgets('sürükleyerek slot seçilir', (tester) async {
    final pool = NotationPitch.poolForMidiRange(
      StaffExerciseRange.minMidi,
      StaffExerciseRange.maxMidi,
    );
    final slots = pool.map((e) => e.staffSlot).toList()..sort();
    var picked = slots.first;
    final g = StaffGeometry.forExercisePool(
      const Size(300, 360),
      poolSlotMin: slots.first,
      poolSlotMax: slots.last,
    );
    const targetSlot = 3;
    final targetY = g.yForSlot(targetSlot);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 360,
            child: StaffInteractiveField(
              fitExercisePool: true,
              layoutSlots: slots,
              pickableSlots: slots,
              notes: const [],
              onSlot: (s) => picked = s,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final staffFinder = find.byType(StaffInteractiveField);
    final box = tester.renderObject(staffFinder) as RenderBox;
    final origin = box.localToGlobal(Offset.zero);
    final tapX = origin.dx + g.noteHeadX;
    final tapY = origin.dy + targetY;

    final gesture = await tester.startGesture(Offset(tapX, tapY));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 4));
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(picked, targetSlot);
  });
}
