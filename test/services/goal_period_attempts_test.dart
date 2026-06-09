import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/exercise_goal.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/goal_period_attempts.dart';

void main() {
  test('aktif hedefte yalnizca startedAtMillis sonrasi denemeler', () {
    const ex = AppStrings.exerciseMcq;
    const goal = ExerciseGoal(
      enabled: true,
      target: 50,
      progress: 3,
      startedAtMillis: 1000,
    );
    final all = [
      PracticeAttempt(
        exercise: ex,
        midi: 60,
        correct: true,
        latencyMs: 100,
        atMillis: 500,
      ),
      PracticeAttempt(
        exercise: ex,
        midi: 62,
        correct: false,
        latencyMs: 200,
        atMillis: 1500,
      ),
      PracticeAttempt(
        exercise: ex,
        midi: 64,
        correct: true,
        latencyMs: 150,
        atMillis: 2000,
      ),
    ];
    final rows = GoalPeriodAttempts.forExercise(
      all: all,
      exerciseId: ex,
      goal: goal,
    );
    expect(rows.length, 2);
    expect(rows.first.atMillis, 1500);
    expect(rows.last.atMillis, 2000);
  });

  test('hedef kapaliysa tum egzersiz denemeleri', () {
    const ex = AppStrings.exerciseMcq;
    final all = [
      PracticeAttempt(
        exercise: ex,
        midi: 60,
        correct: true,
        latencyMs: 100,
        atMillis: 100,
      ),
    ];
    final rows = GoalPeriodAttempts.forExercise(
      all: all,
      exerciseId: ex,
      goal: const ExerciseGoal(enabled: false),
    );
    expect(rows.length, 1);
  });
}
