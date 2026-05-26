import '../models/practice_attempt.dart';

/// Günlük pratik serisi: ardışık takvim günlerinde en az bir deneme.
abstract final class PracticeStreak {
  static int currentStreak(List<PracticeAttempt> attempts, {DateTime? now}) {
    if (attempts.isEmpty) {
      return 0;
    }
    final clock = now ?? DateTime.now();
    final days = attempts
        .map((a) => _dayKey(DateTime.fromMillisecondsSinceEpoch(a.atMillis)))
        .toSet()
        .toList()
      ..sort();
    if (days.isEmpty) {
      return 0;
    }
    final today = _dayKey(clock);
    final yesterday = _dayKey(clock.subtract(const Duration(days: 1)));
    if (!days.contains(today) && !days.contains(yesterday)) {
      return 0;
    }
    var cursor = days.contains(today)
        ? DateTime(clock.year, clock.month, clock.day)
        : DateTime(clock.year, clock.month, clock.day)
            .subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(_dayKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static int _dayKey(DateTime d) => d.year * 10000 + d.month * 100 + d.day;
}
