import '../config/goal_kind.dart';
import '../models/practice_attempt.dart';
import '../models/practice_prefs.dart';
import '../services/stats_summary.dart';

final class GoalProgressSnapshot {
  const GoalProgressSnapshot({
    required this.goalTitle,
    required this.attemptsDone,
    required this.attemptTarget,
    required this.accuracyPercent,
    required this.accuracyTargetPercent,
    required this.avgLatencyMs,
    required this.maxAvgLatencyTargetMs,
  });

  final String goalTitle;
  final int attemptsDone;
  final int attemptTarget;
  final int accuracyPercent;
  final int accuracyTargetPercent;
  final int? avgLatencyMs;
  final int maxAvgLatencyTargetMs;

  double get attemptProgress =>
      attemptTarget <= 0 ? 0 : (attemptsDone / attemptTarget).clamp(0, 1);

  double get accuracyProgress => accuracyTargetPercent <= 0
      ? 0
      : (accuracyPercent / accuracyTargetPercent).clamp(0, 1);

  /// 1.0 = hedef hızda veya daha hızlı.
  double get speedProgress {
    if (avgLatencyMs == null || maxAvgLatencyTargetMs <= 0) {
      return 0;
    }
    if (avgLatencyMs! <= maxAvgLatencyTargetMs) {
      return 1;
    }
    final ratio = maxAvgLatencyTargetMs / avgLatencyMs!;
    return ratio.clamp(0, 1);
  }

  static GoalProgressSnapshot? forKind({
    required String kind,
    required PracticePrefs prefs,
    required List<PracticeAttempt> all,
  }) {
    final goal = prefs.goalForKind(kind);
    if (goal == null) {
      return null;
    }
    final ex = GoalKind.exerciseId(kind);
    if (ex == null) {
      return null;
    }
    final started = goal.startedAtMillis;
    final rows = all.where((r) {
      if (r.exercise != ex) {
        return false;
      }
      if (started > 0) {
        return r.atMillis >= started;
      }
      return true;
    }).toList();
    final summary = summarizeAttempts(rows);
    return GoalProgressSnapshot(
      goalTitle: GoalKind.titleWithFallback(kind),
      attemptsDone: goal.progress.clamp(0, goal.target),
      attemptTarget: goal.target,
      accuracyPercent: (summary.accuracy * 100).round(),
      accuracyTargetPercent: goal.accuracyPercent,
      avgLatencyMs: summary.avgLatencyMs,
      maxAvgLatencyTargetMs: goal.maxAvgLatencyMs,
    );
  }
}
