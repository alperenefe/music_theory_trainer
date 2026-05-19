import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/goal_kind.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/exercise_goal.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:music_theory_trainer/services/goal_progress_snapshot.dart';

void main() {
  test('forKind doğruluk ve hız hesaplar', () {
    const prefs = PracticePrefs(
      exerciseGoals: {
        GoalKind.interval: ExerciseGoal(
          enabled: true,
          target: 10,
          progress: 2,
          startedAtMillis: 1000,
          accuracyPercent: 80,
          maxAvgLatencyMs: 2000,
        ),
      },
    );
    final attempts = [
      PracticeAttempt(
        exercise: AppStrings.exerciseInterval,
        midi: 60,
        correct: true,
        latencyMs: 1000,
        atMillis: 1500,
      ),
      PracticeAttempt(
        exercise: AppStrings.exerciseInterval,
        midi: 62,
        correct: false,
        latencyMs: 3000,
        atMillis: 1600,
      ),
    ];
    final snap = GoalProgressSnapshot.forKind(
      kind: GoalKind.interval,
      prefs: prefs,
      all: attempts,
    )!;
    expect(snap.attemptsDone, 2);
    expect(snap.attemptTarget, 10);
    expect(snap.accuracyPercent, 50);
    expect(snap.speedProgress, 1);
  });

  test('hedef kapalıysa null', () {
    expect(
      GoalProgressSnapshot.forKind(
        kind: GoalKind.mcq,
        prefs: const PracticePrefs(),
        all: const [],
      ),
      isNull,
    );
  });

  test('legacy json tek hedefi exerciseGoals yapar', () {
    final p = PracticePrefs.fromJson({
      'goalKind': 'mcq',
      'goalTarget': 50,
      'goalProgress': 3,
      'goalStartedAtMillis': 99,
      'goalAccuracyPercent': 90,
      'goalMaxAvgLatencyMs': 2000,
    });
    final g = p.exerciseGoals['mcq']!;
    expect(g.enabled, isTrue);
    expect(g.target, 50);
    expect(g.progress, 3);
    expect(g.accuracyPercent, 90);
  });
}
