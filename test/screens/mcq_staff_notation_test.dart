import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/staff_exercise_range.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';

/// Notayı tanı (MCQ) portede aynı havuz ve staffSlot kullanır.
void main() {
  test('MCQ havuzu yerleştir ile aynı aralık ve yazım', () {
    final pool = NotationPitch.poolForMidiRange(
      StaffExerciseRange.minMidi,
      StaffExerciseRange.maxMidi,
    );
    final inceMi = pool.firstWhere((p) => p.midi == 64);
    expect(inceMi.staffSlot, 7);
    expect(pool.any((p) => p.midi == 71), isTrue);
  });
}
