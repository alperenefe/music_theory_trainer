import '../l10n/app_strings.dart';
import '../models/practice_attempt.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../services/stats_summary.dart';

final class GoalCompletionReport {
  const GoalCompletionReport({
    required this.goalTitle,
    required this.target,
    required this.summary,
    required this.bestStreak,
    required this.totalWrong,
    this.medianLatencyMs,
    required this.totalThinkingMs,
  });

  final String goalTitle;
  final int target;
  final StatsSummary summary;
  final int bestStreak;
  final int totalWrong;
  final int? medianLatencyMs;
  final int totalThinkingMs;
}

final class GoalTracker {
  static Future<GoalCompletionReport?> onAttemptRecorded({
    required String exercise,
    required StatsRepository statsRepo,
    required PracticePrefsRepository prefsRepo,
  }) async {
    final prefs = await prefsRepo.load();
    final gk = prefs.goalKind;
    if (gk == null) {
      return null;
    }
    if (!_matches(gk, exercise)) {
      return null;
    }
    final started = prefs.goalStartedAtMillis;
    final target = prefs.goalTarget.clamp(1, 999999);
    final next = prefs.goalProgress + 1;
    if (next < target) {
      await prefsRepo.save(prefs.copyWith(goalProgress: next));
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
      goalTitle: _kindTitle(gk),
      target: target,
      summary: summary,
      bestStreak: _bestStreak(window),
      totalWrong: summary.total - summary.correct,
      medianLatencyMs: _medianMs(window),
      totalThinkingMs: think,
    );
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefsRepo.save(
      prefs.copyWith(goalProgress: 0, goalStartedAtMillis: now),
    );
    return report;
  }

  static bool _matches(String goalKind, String exercise) {
    return (goalKind == 'placement' &&
            exercise == AppStrings.exercisePlacement) ||
        (goalKind == 'mcq' && exercise == AppStrings.exerciseMcq) ||
        (goalKind == 'gitar_mcq' && exercise == AppStrings.exerciseGuitarMcq) ||
        (goalKind == 'gitar_bul' && exercise == AppStrings.exerciseGuitarFind) ||
        (goalKind == 'gitar_cal' && exercise == AppStrings.exerciseGuitarPlay);
  }

  static String _kindTitle(String goalKind) {
    return switch (goalKind) {
      'placement' => AppStrings.placementTitle,
      'mcq' => AppStrings.mcqTitle,
      'gitar_mcq' => AppStrings.guitarMcqTitle,
      'gitar_bul' => AppStrings.guitarFindTitle,
      'gitar_cal' => AppStrings.guitarPlayTitle,
      _ => AppStrings.goalsTitle,
    };
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
