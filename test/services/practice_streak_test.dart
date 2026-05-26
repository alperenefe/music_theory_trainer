import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/practice_streak.dart';

void main() {
  test('bugün deneme varsa seri en az 1', () {
    final now = DateTime(2026, 5, 19, 12);
    final attempts = [
      PracticeAttempt(
        exercise: 'x',
        midi: 60,
        correct: true,
        latencyMs: 100,
        atMillis: now.millisecondsSinceEpoch,
      ),
    ];
    expect(PracticeStreak.currentStreak(attempts, now: now), 1);
  });

  test('dün ve bugün ardışık seri 2', () {
    final now = DateTime(2026, 5, 19, 12);
    final yesterday = DateTime(2026, 5, 18, 12);
    final attempts = [
      PracticeAttempt(
        exercise: 'x',
        midi: 60,
        correct: true,
        latencyMs: 100,
        atMillis: yesterday.millisecondsSinceEpoch,
      ),
      PracticeAttempt(
        exercise: 'x',
        midi: 60,
        correct: true,
        latencyMs: 100,
        atMillis: now.millisecondsSinceEpoch,
      ),
    ];
    expect(PracticeStreak.currentStreak(attempts, now: now), 2);
  });
}
