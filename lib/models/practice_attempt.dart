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

  static int _i(Object? v) {
    if (v is int) {
      return v;
    }
    if (v is num) {
      return v.toInt();
    }
    throw FormatException('int bekleniyordu: $v');
  }

  static PracticeAttempt fromJson(Map<String, Object?> j) {
    return PracticeAttempt(
      exercise: j['exercise']! as String,
      midi: _i(j['midi']),
      correct: j['correct']! as bool,
      latencyMs: _i(j['latencyMs']),
      atMillis: _i(j['atMillis']),
    );
  }
}
