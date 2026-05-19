import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/practice_history.dart';

void main() {
  test('forExercise yalnızca eşleşen denemeleri döner', () {
    final all = [
      const PracticeAttempt(
        exercise: 'yerlestir',
        midi: 60,
        correct: true,
        latencyMs: 10,
        atMillis: 1,
      ),
      const PracticeAttempt(
        exercise: 'gitar_mcq',
        midi: 64,
        correct: false,
        latencyMs: 20,
        atMillis: 2,
      ),
    ];
    final staff = PracticeHistory.forExercise(all, 'yerlestir');
    expect(staff.length, 1);
    expect(staff.first.midi, 60);
  });
}
