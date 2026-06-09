import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/utils/attempt_outcome_format.dart';

void main() {
  test('formatOutcomeChain D Y', () {
    expect(formatOutcomeChain([true, false, true]), 'D Y D');
  });

  test('outcomesForMidi son denemeler', () {
    final rows = [
      PracticeAttempt(
        exercise: 'x',
        midi: 60,
        correct: true,
        latencyMs: 100,
        atMillis: 1,
      ),
      PracticeAttempt(
        exercise: 'x',
        midi: 62,
        correct: false,
        latencyMs: 100,
        atMillis: 2,
      ),
      PracticeAttempt(
        exercise: 'x',
        midi: 60,
        correct: false,
        latencyMs: 100,
        atMillis: 3,
      ),
    ];
    expect(outcomesForMidi(rows, 60), [true, false]);
  });
}
