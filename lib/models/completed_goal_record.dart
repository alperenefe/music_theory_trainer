import 'goal_completion_report.dart';
import '../services/stats_summary.dart';

/// Tamamlanan hedef özeti; nota kırılımı olmadan da gösterilebilir.
final class CompletedGoalRecord {
  static const int maxStored = 50;

  const CompletedGoalRecord({
    required this.kind,
    required this.goalTitle,
    required this.target,
    required this.completedAtMillis,
    required this.total,
    required this.correct,
    this.avgLatencyMs,
    required this.bestStreak,
    required this.totalWrong,
    this.medianLatencyMs,
    required this.totalThinkingMs,
    this.midiStats = const [],
  });

  final String kind;
  final String goalTitle;
  final int target;
  final int completedAtMillis;
  final int total;
  final int correct;
  final int? avgLatencyMs;
  final int bestStreak;
  final int totalWrong;
  final int? medianLatencyMs;
  final int totalThinkingMs;
  final List<MidiStat> midiStats;

  double get accuracy => total == 0 ? 0 : correct / total;

  factory CompletedGoalRecord.fromReport({
    required String kind,
    required GoalCompletionReport report,
    required int completedAtMillis,
  }) {
    return CompletedGoalRecord(
      kind: kind,
      goalTitle: report.goalTitle,
      target: report.target,
      completedAtMillis: completedAtMillis,
      total: report.summary.total,
      correct: report.summary.correct,
      avgLatencyMs: report.summary.avgLatencyMs,
      bestStreak: report.bestStreak,
      totalWrong: report.totalWrong,
      medianLatencyMs: report.medianLatencyMs,
      totalThinkingMs: report.totalThinkingMs,
      midiStats: report.summary.midiStats,
    );
  }

  GoalCompletionReport toReport() {
    return GoalCompletionReport(
      goalTitle: goalTitle,
      target: target,
      summary: StatsSummary(
        total: total,
        correct: correct,
        avgLatencyMs: avgLatencyMs,
        midiStats: midiStats,
      ),
      bestStreak: bestStreak,
      totalWrong: totalWrong,
      medianLatencyMs: medianLatencyMs,
      totalThinkingMs: totalThinkingMs,
    );
  }

  Map<String, Object?> toJson() => {
    'kind': kind,
    'goalTitle': goalTitle,
    'target': target,
    'completedAtMillis': completedAtMillis,
    'total': total,
    'correct': correct,
    'avgLatencyMs': avgLatencyMs,
    'bestStreak': bestStreak,
    'totalWrong': totalWrong,
    'medianLatencyMs': medianLatencyMs,
    'totalThinkingMs': totalThinkingMs,
    'midiStats': midiStats.map(_midiStatToJson).toList(),
  };

  static CompletedGoalRecord fromJson(Map<String, Object?> j) {
    int ni(Object? v, int d) {
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return d;
    }

    int? niOpt(Object? v) {
      if (v == null) {
        return null;
      }
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return null;
    }

    final statsRaw = j['midiStats'];
    final stats = <MidiStat>[];
    if (statsRaw is List) {
      for (final e in statsRaw) {
        if (e is Map) {
          stats.add(_midiStatFromJson(Map<String, Object?>.from(e)));
        }
      }
    }

    return CompletedGoalRecord(
      kind: j['kind']?.toString() ?? '',
      goalTitle: j['goalTitle']?.toString() ?? '',
      target: ni(j['target'], 0),
      completedAtMillis: ni(j['completedAtMillis'], 0),
      total: ni(j['total'], 0),
      correct: ni(j['correct'], 0),
      avgLatencyMs: niOpt(j['avgLatencyMs']),
      bestStreak: ni(j['bestStreak'], 0),
      totalWrong: ni(j['totalWrong'], 0),
      medianLatencyMs: niOpt(j['medianLatencyMs']),
      totalThinkingMs: ni(j['totalThinkingMs'], 0),
      midiStats: stats,
    );
  }

  static Map<String, Object?> _midiStatToJson(MidiStat m) => {
    'midi': m.midi,
    'total': m.total,
    'correct': m.correct,
    'avgMs': m.avgMs,
  };

  static MidiStat _midiStatFromJson(Map<String, Object?> j) {
    int ni(Object? v, int d) {
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return d;
    }

    return MidiStat(
      midi: ni(j['midi'], 60),
      total: ni(j['total'], 0),
      correct: ni(j['correct'], 0),
      avgMs: ni(j['avgMs'], 0),
    );
  }
}
