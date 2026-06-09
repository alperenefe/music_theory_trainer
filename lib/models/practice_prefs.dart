import 'completed_goal_record.dart';
import 'custom_workout.dart';
import 'exercise_goal.dart';

final class PracticePrefs {
  static const int defaultPoolMinMidi = 40;
  static const int defaultPoolMaxMidi = 71;
  static const double defaultReferenceA4Hz = 440;

  const PracticePrefs({
    this.poolMinMidi = PracticePrefs.defaultPoolMinMidi,
    this.poolMaxMidi = PracticePrefs.defaultPoolMaxMidi,
    this.exerciseGoals = const {},
    this.completedGoals = const [],
    this.customWorkout,
    this.soundEnabled = true,
    this.onboardingDone = false,
    this.referenceA4Hz = PracticePrefs.defaultReferenceA4Hz,
  });

  final int poolMinMidi;
  final int poolMaxMidi;
  final Map<String, ExerciseGoal> exerciseGoals;
  final List<CompletedGoalRecord> completedGoals;
  final CustomWorkout? customWorkout;
  final bool soundEnabled;
  final bool onboardingDone;
  final double referenceA4Hz;

  ExerciseGoal? goalForKind(String kind) {
    final g = exerciseGoals[kind];
    if (g == null || !g.enabled) {
      return null;
    }
    return g;
  }

  PracticePrefs withGoal(String kind, ExerciseGoal? goal) {
    final next = Map<String, ExerciseGoal>.from(exerciseGoals);
    if (goal == null || !goal.enabled) {
      next.remove(kind);
    } else {
      next[kind] = goal;
    }
    return copyWith(exerciseGoals: next);
  }

  PracticePrefs withCompletedGoal(CompletedGoalRecord record) {
    final next = [record, ...completedGoals];
    final capped = next.length > CompletedGoalRecord.maxStored
        ? next.sublist(0, CompletedGoalRecord.maxStored)
        : next;
    return copyWith(completedGoals: capped);
  }

  PracticePrefs copyWith({
    int? poolMinMidi,
    int? poolMaxMidi,
    Map<String, ExerciseGoal>? exerciseGoals,
    List<CompletedGoalRecord>? completedGoals,
    CustomWorkout? customWorkout,
    bool? soundEnabled,
    bool? onboardingDone,
    double? referenceA4Hz,
  }) {
    return PracticePrefs(
      poolMinMidi: poolMinMidi ?? this.poolMinMidi,
      poolMaxMidi: poolMaxMidi ?? this.poolMaxMidi,
      exerciseGoals: exerciseGoals ?? this.exerciseGoals,
      completedGoals: completedGoals ?? this.completedGoals,
      customWorkout: customWorkout ?? this.customWorkout,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      referenceA4Hz: referenceA4Hz ?? this.referenceA4Hz,
    );
  }

  Map<String, Object?> toJson() => {
    'poolMinMidi': poolMinMidi,
    'poolMaxMidi': poolMaxMidi,
    'exerciseGoals': exerciseGoals.map(
      (k, v) => MapEntry(k, v.toJson()),
    ),
    'completedGoals': completedGoals.map((e) => e.toJson()).toList(),
    if (customWorkout != null) 'customWorkout': customWorkout!.toJson(),
    'soundEnabled': soundEnabled,
    'onboardingDone': onboardingDone,
    'referenceA4Hz': referenceA4Hz,
  };

  static PracticePrefs fromJson(Map<String, Object?> j) {
    int ni(Object? v, int d) {
      if (v is int) {
        return v;
      }
      if (v is num) {
        return v.toInt();
      }
      return d;
    }

    double nd(Object? v, double d) {
      if (v is double) {
        return v;
      }
      if (v is int) {
        return v.toDouble();
      }
      if (v is num) {
        return v.toDouble();
      }
      return d;
    }

    var soundEnabled = true;
    if (j.containsKey('soundEnabled')) {
      soundEnabled = j['soundEnabled'] != false;
    }
    final onboardingDone = _parseOnboardingDone(j);

    var ref = nd(j['referenceA4Hz'], defaultReferenceA4Hz);
    if (ref < 415) {
      ref = 415;
    }
    if (ref > 455) {
      ref = 455;
    }

    final goals = _parseExerciseGoals(j, ni);
    final completed = _parseCompletedGoals(j);
    final custom = _parseCustomWorkout(j);

    return PracticePrefs(
      poolMinMidi: ni(j['poolMinMidi'], defaultPoolMinMidi),
      poolMaxMidi: ni(j['poolMaxMidi'], defaultPoolMaxMidi),
      exerciseGoals: goals,
      completedGoals: completed,
      customWorkout: custom,
      soundEnabled: soundEnabled,
      onboardingDone: onboardingDone,
      referenceA4Hz: ref,
    );
  }

  static CustomWorkout? _parseCustomWorkout(Map<String, Object?> j) {
    final raw = j['customWorkout'];
    if (raw is! Map) {
      return null;
    }
    return CustomWorkout.fromJson(Map<String, Object?>.from(raw));
  }

  static List<CompletedGoalRecord> _parseCompletedGoals(
    Map<String, Object?> j,
  ) {
    final raw = j['completedGoals'];
    if (raw is! List) {
      return const [];
    }
    final out = <CompletedGoalRecord>[];
    for (final e in raw) {
      if (e is Map) {
        out.add(
          CompletedGoalRecord.fromJson(Map<String, Object?>.from(e)),
        );
      }
    }
    if (out.length > CompletedGoalRecord.maxStored) {
      return out.sublist(0, CompletedGoalRecord.maxStored);
    }
    return out;
  }

  static Map<String, ExerciseGoal> _parseExerciseGoals(
    Map<String, Object?> j,
    int Function(Object?, int) ni,
  ) {
    final raw = j['exerciseGoals'];
    if (raw is Map) {
      final out = <String, ExerciseGoal>{};
      for (final e in raw.entries) {
        final key = e.key.toString();
        final val = e.value;
        if (val is Map) {
          out[key] = ExerciseGoal.fromJson(
            Map<String, Object?>.from(val),
          );
        }
      }
      return out;
    }

    final legacyKind = j['goalKind'] as String?;
    if (legacyKind == null || legacyKind.isEmpty) {
      return {};
    }
    return {
      legacyKind: ExerciseGoal(
        enabled: true,
        target: ni(j['goalTarget'], ExerciseGoal.defaultTarget),
        progress: ni(j['goalProgress'], 0),
        startedAtMillis: ni(j['goalStartedAtMillis'], 0),
        accuracyPercent: ni(
          j['goalAccuracyPercent'],
          ExerciseGoal.defaultAccuracyPercent,
        ).clamp(50, 100),
        maxAvgLatencyMs: ni(
          j['goalMaxAvgLatencyMs'],
          ExerciseGoal.defaultMaxAvgLatencyMs,
        ).clamp(800, 30000),
      ),
    };
  }

  static bool _parseOnboardingDone(Map<String, Object?> j) {
    if (!j.containsKey('onboardingDone')) {
      return true;
    }
    final v = j['onboardingDone'];
    if (v == true) {
      return true;
    }
    if (v == false) {
      return false;
    }
    if (v is num && v.toInt() == 1) {
      return true;
    }
    if (v is String && v.toLowerCase() == 'true') {
      return true;
    }
    return false;
  }
}
