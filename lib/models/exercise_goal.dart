final class ExerciseGoal {
  static const int defaultTarget = 100;
  static const int defaultAccuracyPercent = 85;
  static const int defaultMaxAvgLatencyMs = 3500;

  const ExerciseGoal({
    this.enabled = false,
    this.target = defaultTarget,
    this.progress = 0,
    this.startedAtMillis = 0,
    this.accuracyPercent = defaultAccuracyPercent,
    this.maxAvgLatencyMs = defaultMaxAvgLatencyMs,
  });

  final bool enabled;
  final int target;
  final int progress;
  final int startedAtMillis;
  final int accuracyPercent;
  final int maxAvgLatencyMs;

  ExerciseGoal copyWith({
    bool? enabled,
    int? target,
    int? progress,
    int? startedAtMillis,
    int? accuracyPercent,
    int? maxAvgLatencyMs,
  }) {
    return ExerciseGoal(
      enabled: enabled ?? this.enabled,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      startedAtMillis: startedAtMillis ?? this.startedAtMillis,
      accuracyPercent: accuracyPercent ?? this.accuracyPercent,
      maxAvgLatencyMs: maxAvgLatencyMs ?? this.maxAvgLatencyMs,
    );
  }

  Map<String, Object?> toJson() => {
    'enabled': enabled,
    'target': target,
    'progress': progress,
    'startedAtMillis': startedAtMillis,
    'accuracyPercent': accuracyPercent,
    'maxAvgLatencyMs': maxAvgLatencyMs,
  };

  static ExerciseGoal fromJson(Map<String, Object?> j) {
    int ni(Object? v, int d) {
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return d;
    }

    return ExerciseGoal(
      enabled: j['enabled'] == true,
      target: ni(j['target'], defaultTarget).clamp(1, 10000),
      progress: ni(j['progress'], 0).clamp(0, 10000),
      startedAtMillis: ni(j['startedAtMillis'], 0),
      accuracyPercent: ni(j['accuracyPercent'], defaultAccuracyPercent)
          .clamp(50, 100),
      maxAvgLatencyMs: ni(j['maxAvgLatencyMs'], defaultMaxAvgLatencyMs)
          .clamp(800, 30000),
    );
  }
}
