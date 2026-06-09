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
