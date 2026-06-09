import '../config/goal_kind.dart';
import '../models/completed_goal_record.dart';
import '../models/goal_completion_report.dart';
import '../models/practice_attempt.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../services/stats_summary.dart';

export '../models/goal_completion_report.dart';

final class GoalTracker {
  static Future<GoalCompletionReport?> onAttemptRecorded({
    required String exercise,
    required StatsRepository statsRepo,
    required PracticePrefsRepository prefsRepo,
  }) async {
    final prefs = await prefsRepo.load();
    final kind = GoalKind.kindForExercise(exercise);
    if (kind == null) {
      return null;
    }
    final goal = prefs.goalForKind(kind);
    if (goal == null) {
      return null;
    }
    final started = goal.startedAtMillis;
    final target = goal.target.clamp(1, 999999);
    final nextProgress = goal.progress + 1;
    if (nextProgress < target) {
      await prefsRepo.save(
        prefs.withGoal(kind, goal.copyWith(progress: nextProgress)),
      );
      return null;
    }
    final rows = await statsRepo.load();
    final matching = rows.where((r) => r.exercise == exercise).toList()
      ..sort((a, b) => a.atMillis.compareTo(b.atMillis));
    final List<PracticeAttempt> window;
    if (started <= 0) {
      window = matching.length <= target
          ? matching
          : matching.sublist(matching.length - target);
    } else {
      window = matching.where((r) => r.atMillis >= started).toList();
    }
    var think = 0;
    for (final r in window) {
      think += r.latencyMs;
    }
    final summary = summarizeAttempts(window);
    final report = GoalCompletionReport(
      goalTitle: GoalKind.titleWithFallback(kind),
      target: target,
      summary: summary,
      bestStreak: _bestStreak(window),
      totalWrong: summary.total - summary.correct,
      medianLatencyMs: _medianMs(window),
      totalThinkingMs: think,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    final record = CompletedGoalRecord.fromReport(
      kind: kind,
      report: report,
      completedAtMillis: now,
    );
    await prefsRepo.save(
      prefs
          .withGoal(
            kind,
            goal.copyWith(progress: 0, startedAtMillis: now),
          )
          .withCompletedGoal(record),
    );
    return report;
  }

  static int _bestStreak(List<PracticeAttempt> rows) {
    if (rows.isEmpty) {
      return 0;
    }
    final sorted = [...rows]..sort((a, b) => a.atMillis.compareTo(b.atMillis));
    var cur = 0;
    var best = 0;
    for (final r in sorted) {
      if (r.correct) {
        cur++;
        if (cur > best) {
          best = cur;
        }
      } else {
        cur = 0;
      }
    }
    return best;
  }

  static int? _medianMs(List<PracticeAttempt> rows) {
    if (rows.isEmpty) {
      return null;
    }
    final xs = rows.map((e) => e.latencyMs).toList()..sort();
    final m = xs.length ~/ 2;
    if (xs.length.isOdd) {
      return xs[m];
    }
    return ((xs[m - 1] + xs[m]) / 2).round();
  }
}
