import '../models/practice_attempt.dart';

final class MidiStat {
  const MidiStat({
    required this.midi,
    required this.total,
    required this.correct,
    required this.avgMs,
  });

  final int midi;
  final int total;
  final int correct;
  final int avgMs;

  double get accuracy => total == 0 ? 0 : correct / total;
}

final class StatsSummary {
  const StatsSummary({
    required this.total,
    required this.correct,
    required this.avgLatencyMs,
    required this.midiStats,
  });

  final int total;
  final int correct;
  final int? avgLatencyMs;
  final List<MidiStat> midiStats;

  double get accuracy => total == 0 ? 0 : correct / total;
}

StatsSummary summarizeAttempts(List<PracticeAttempt> rows) {
  if (rows.isEmpty) {
    return const StatsSummary(
      total: 0,
      correct: 0,
      avgLatencyMs: null,
      midiStats: [],
    );
  }
  var c = 0;
  var sum = 0;
  final map = <int, _Agg>{};
  for (final r in rows) {
    if (r.correct) {
      c++;
    }
    sum += r.latencyMs;
    final m = map.putIfAbsent(r.midi, () => _Agg());
    m.total++;
    if (r.correct) {
      m.correct++;
    }
    m.sumMs += r.latencyMs;
  }
  final list =
      map.entries
          .map(
            (e) => MidiStat(
              midi: e.key,
              total: e.value.total,
              correct: e.value.correct,
              avgMs: e.value.total == 0
                  ? 0
                  : (e.value.sumMs / e.value.total).round(),
            ),
          )
          .toList()
        ..sort((a, b) => a.midi.compareTo(b.midi));
  return StatsSummary(
    total: rows.length,
    correct: c,
    avgLatencyMs: (sum / rows.length).round(),
    midiStats: list,
  );
}

final class _Agg {
  int total = 0;
  int correct = 0;
  int sumMs = 0;
}
