import 'ear_exercise_kind.dart';

/// Seansın türü: normal pratik, boss meydan okuması veya aralıklı tekrar.
enum EarSessionMode {
  practice,
  boss,
  review;

  /// Tekrar seansları eski konuları kapsar; aktif haftanın barajına sayılmaz.
  bool get countsTowardGate => this != EarSessionMode.review;

  static EarSessionMode fromName(Object? name) {
    for (final m in values) {
      if (m.name == name) return m;
    }
    return EarSessionMode.practice;
  }
}

final class EarSessionResult {
  const EarSessionResult({
    required this.kind,
    required this.weekNumber,
    required this.totalQuestions,
    required this.correctCount,
    this.errorsBySubtype = const {},
    this.attemptsBySubtype = const {},
    required this.durationSeconds,
    required this.completedAt,
    this.mode = EarSessionMode.practice,
  });

  final EarExerciseKind kind;
  final int weekNumber;
  final int totalQuestions;
  final int correctCount;
  final Map<String, int> errorsBySubtype;
  /// Alt tür başına toplam soru sayısı (doğru+yanlış) — [errorsBySubtype]
  /// ile birlikte hata ORANI hesaplamak için gereken payda.
  final Map<String, int> attemptsBySubtype;
  final int durationSeconds;
  final DateTime completedAt;
  final EarSessionMode mode;

  double get accuracy =>
      totalQuestions == 0 ? 0.0 : correctCount / totalQuestions;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'weekNumber': weekNumber,
        'totalQuestions': totalQuestions,
        'correctCount': correctCount,
        'errorsBySubtype': errorsBySubtype,
        'attemptsBySubtype': attemptsBySubtype,
        'durationSeconds': durationSeconds,
        'completedAt': completedAt.millisecondsSinceEpoch,
        'mode': mode.name,
      };

  static EarSessionResult fromJson(Map<String, Object?> j) {
    int ni(Object? v, int d) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return d;
    }

    final kindStr = j['kind'];
    final kind = EarExerciseKind.values.firstWhere(
      (k) => k.name == kindStr,
      orElse: () => EarExerciseKind.intervalBlind,
    );

    final rawErr = j['errorsBySubtype'];
    final errors = <String, int>{};
    if (rawErr is Map) {
      for (final e in rawErr.entries) {
        errors[e.key.toString()] = ni(e.value, 0);
      }
    }

    final rawAttempts = j['attemptsBySubtype'];
    final attempts = <String, int>{};
    if (rawAttempts is Map) {
      for (final e in rawAttempts.entries) {
        attempts[e.key.toString()] = ni(e.value, 0);
      }
    }

    final epoch = j['completedAt'];
    final completedAt = epoch is num
        ? DateTime.fromMillisecondsSinceEpoch(epoch.toInt())
        : DateTime.now();

    return EarSessionResult(
      kind: kind,
      weekNumber: ni(j['weekNumber'], 1),
      totalQuestions: ni(j['totalQuestions'], 0),
      correctCount: ni(j['correctCount'], 0),
      errorsBySubtype: errors,
      attemptsBySubtype: attempts,
      durationSeconds: ni(j['durationSeconds'], 0),
      completedAt: completedAt,
      mode: EarSessionMode.fromName(j['mode']),
    );
  }
}
