import '../models/exercise_goal.dart';
import '../models/practice_attempt.dart';
import 'stats_repository.dart';

/// Aktif hedef varsa yalnizca [ExerciseGoal.startedAtMillis] sonrasi denemeler.
abstract final class GoalPeriodAttempts {
  static List<PracticeAttempt> forExercise({
    required List<PracticeAttempt> all,
    required String exerciseId,
    required ExerciseGoal? goal,
    int limit = StatsRepository.defaultExerciseWindow,
  }) {
    final rows = all.where((r) {
      if (r.exercise != exerciseId) {
        return false;
      }
      if (goal == null || !goal.enabled) {
        return true;
      }
      final started = goal.startedAtMillis;
      if (started > 0) {
        return r.atMillis >= started;
      }
      return true;
    }).toList();
    if (rows.length <= limit) {
      return rows;
    }
    return rows.sublist(rows.length - limit);
  }
}
