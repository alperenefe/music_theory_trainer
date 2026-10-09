final class PracticeAttempt {
  const PracticeAttempt({
    required this.exercise,
    required this.midi,
    required this.correct,
    required this.latencyMs,
    required this.atMillis,
  });

  final String exercise;
  final int midi;
  final bool correct;
  final int latencyMs;
  final int atMillis;

  Map<String, Object?> toJson() => {
    'exercise': exercise,
    'midi': midi,
    'correct': correct,
    'latencyMs': latencyMs,
    'atMillis': atMillis,
  };

  static int _i(Object? v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  static bool _b(Object? v, [bool fallback = false]) {
    if (v is bool) return v;
    return fallback;
  }

  static String _s(Object? v, [String fallback = '']) {
    if (v is String) return v;
    return fallback;
  }

  static PracticeAttempt fromJson(Map<String, Object?> j) {
    return PracticeAttempt(
      exercise: _s(j['exercise']),
      midi: _i(j['midi']),
      correct: _b(j['correct']),
      latencyMs: _i(j['latencyMs']),
      atMillis: _i(j['atMillis']),
    );
  }
}
