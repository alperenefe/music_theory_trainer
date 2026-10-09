import 'completed_goal_record.dart';
import 'custom_workout.dart';
import 'ear_session_result.dart';
import 'exercise_goal.dart';
import 'weekly_progress.dart';

final class PracticePrefs {
  static const int defaultPoolMinMidi = 40;
  static const int defaultPoolMaxMidi = 71;
  static const double defaultReferenceA4Hz = 440;
  static const int defaultCurriculumPhase = 1;

  const PracticePrefs({
    this.poolMinMidi = PracticePrefs.defaultPoolMinMidi,
    this.poolMaxMidi = PracticePrefs.defaultPoolMaxMidi,
    this.exerciseGoals = const {},
    this.completedGoals = const [],
    this.customWorkout,
    this.soundEnabled = true,
    this.onboardingDone = false,
    this.referenceA4Hz = PracticePrefs.defaultReferenceA4Hz,
    this.curriculumPhase = PracticePrefs.defaultCurriculumPhase,
    this.earWeekProgress = const [],
    this.earSessionHistory = const [],
    this.intervalAnchors = const {},
    this.dailyGoalMinutes = defaultDailyGoalMinutes,
    this.guitarPracticeMs = const {},
    this.guitarStepStars = const {},
    this.guitarBests = const {},
  });

  static const int defaultDailyGoalMinutes = 15;
  static const int minDailyGoalMinutes = 5;
  static const int maxDailyGoalMinutes = 120;

  /// Gitar çalışma süresi en fazla bu kadar gün geriye saklanır.
  static const int maxPracticeDays = 120;

  /// Bir günün seriye sayılması için gereken en az gitar çalışma süresi.
  static const int streakMinMs = 3 * 60 * 1000;

  /// Kişisel şarkı çapası anahtarı: `interval_minor3` (yükselen) ya da
  /// `interval_minor3_down` (alçalan).
  static String anchorKey(String intervalSrsKey, {bool descending = false}) =>
      descending ? '${intervalSrsKey}_down' : intervalSrsKey;

  static const int maxAnchorLength = 80;

  final int poolMinMidi;
  final int poolMaxMidi;
  final Map<String, ExerciseGoal> exerciseGoals;
  final List<CompletedGoalRecord> completedGoals;
  final CustomWorkout? customWorkout;
  final bool soundEnabled;
  final bool onboardingDone;
  final double referenceA4Hz;

  /// Porte egzersizlerinde aktif müfredat fazı (1–5).
  final int curriculumPhase;

  /// Kulaktan akor çıkarma 12 haftalık müfredat ilerlemesi.
  final List<WeeklyProgress> earWeekProgress;

  /// Kulak antrenmanı seans geçmişi (son seanslar).
  final List<EarSessionResult> earSessionHistory;

  /// Kullanıcının her aralık için yazdığı kendi referans şarkısı.
  final Map<String, String> intervalAnchors;

  /// Günlük gitar çalışma hedefi (dakika).
  final int dailyGoalMinutes;

  /// Gün (yyyy-MM-dd) → o gün gitar ekranlarında geçirilen süre (ms).
  final Map<String, int> guitarPracticeMs;

  /// Gitar yolu adımı → en iyi yıldız (0–3).
  final Map<String, int> guitarStepStars;

  /// Rekorlar: ör. `changes:A-D` → dakikadaki en iyi akor değişimi.
  final Map<String, int> guitarBests;

  int practiceMsOn(String dayKey) => guitarPracticeMs[dayKey] ?? 0;

  PracticePrefs withPracticeMs(String dayKey, int addMs) {
    if (addMs <= 0) return this;
    final next = Map<String, int>.from(guitarPracticeMs);
    next[dayKey] = (next[dayKey] ?? 0) + addMs;
    if (next.length > maxPracticeDays) {
      final keys = next.keys.toList()..sort();
      for (final k in keys.take(next.length - maxPracticeDays)) {
        next.remove(k);
      }
    }
    return copyWith(guitarPracticeMs: next);
  }

  /// Daha önce kaydedilenden DÜŞÜK bir yıldız mevcut yıldızı silmez.
  PracticePrefs withStepStars(String stepId, int stars) {
    final s = stars.clamp(0, 3);
    if ((guitarStepStars[stepId] ?? -1) >= s) return this;
    return copyWith(guitarStepStars: {...guitarStepStars, stepId: s});
  }

  PracticePrefs withGuitarBest(String key, int value) {
    if ((guitarBests[key] ?? -1) >= value) return this;
    return copyWith(guitarBests: {...guitarBests, key: value});
  }

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
    int? curriculumPhase,
    List<WeeklyProgress>? earWeekProgress,
    List<EarSessionResult>? earSessionHistory,
    Map<String, String>? intervalAnchors,
    int? dailyGoalMinutes,
    Map<String, int>? guitarPracticeMs,
    Map<String, int>? guitarStepStars,
    Map<String, int>? guitarBests,
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
      curriculumPhase: curriculumPhase ?? this.curriculumPhase,
      earWeekProgress: earWeekProgress ?? this.earWeekProgress,
      earSessionHistory: earSessionHistory ?? this.earSessionHistory,
      intervalAnchors: intervalAnchors ?? this.intervalAnchors,
      dailyGoalMinutes: dailyGoalMinutes ?? this.dailyGoalMinutes,
      guitarPracticeMs: guitarPracticeMs ?? this.guitarPracticeMs,
      guitarStepStars: guitarStepStars ?? this.guitarStepStars,
      guitarBests: guitarBests ?? this.guitarBests,
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
    'curriculumPhase': curriculumPhase,
    'earWeekProgress': earWeekProgress.map((e) => e.toJson()).toList(),
    'earSessionHistory': earSessionHistory.map((e) => e.toJson()).toList(),
    if (intervalAnchors.isNotEmpty) 'intervalAnchors': intervalAnchors,
    'dailyGoalMinutes': dailyGoalMinutes,
    if (guitarPracticeMs.isNotEmpty) 'guitarPracticeMs': guitarPracticeMs,
    if (guitarStepStars.isNotEmpty) 'guitarStepStars': guitarStepStars,
    if (guitarBests.isNotEmpty) 'guitarBests': guitarBests,
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

    final phase = ni(j['curriculumPhase'], defaultCurriculumPhase)
        .clamp(1, 5);

    final earProgress = _parseEarWeekProgress(j);
    final earHistory = _parseEarSessionHistory(j);

    return PracticePrefs(
      poolMinMidi: ni(j['poolMinMidi'], defaultPoolMinMidi),
      poolMaxMidi: ni(j['poolMaxMidi'], defaultPoolMaxMidi),
      exerciseGoals: goals,
      completedGoals: completed,
      customWorkout: custom,
      soundEnabled: soundEnabled,
      onboardingDone: onboardingDone,
      referenceA4Hz: ref,
      curriculumPhase: phase,
      earWeekProgress: earProgress,
      earSessionHistory: earHistory,
      intervalAnchors: _parseIntervalAnchors(j),
      dailyGoalMinutes: ni(j['dailyGoalMinutes'], defaultDailyGoalMinutes)
          .clamp(minDailyGoalMinutes, maxDailyGoalMinutes),
      guitarPracticeMs: _parseIntMap(j['guitarPracticeMs'], min: 0),
      guitarStepStars: _parseIntMap(j['guitarStepStars'], min: 0, max: 3),
      guitarBests: _parseIntMap(j['guitarBests'], min: 0),
    );
  }

  static Map<String, int> _parseIntMap(Object? raw, {required int min, int? max}) {
    if (raw is! Map) return const {};
    final out = <String, int>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is! num) continue;
      var n = v.toInt();
      if (n < min) n = min;
      if (max != null && n > max) n = max;
      out[e.key.toString()] = n;
    }
    return out;
  }

  static Map<String, String> _parseIntervalAnchors(Map<String, Object?> j) {
    final raw = j['intervalAnchors'];
    if (raw is! Map) return const {};
    final out = <String, String>{};
    for (final e in raw.entries) {
      final v = e.value;
      if (v is! String) continue;
      final text = v.trim();
      if (text.isEmpty) continue;
      out[e.key.toString()] =
          text.length > maxAnchorLength ? text.substring(0, maxAnchorLength) : text;
    }
    return out;
  }

  static List<WeeklyProgress> _parseEarWeekProgress(Map<String, Object?> j) {
    final raw = j['earWeekProgress'];
    if (raw is! List) return const [];
    final out = <WeeklyProgress>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(WeeklyProgress.fromJson(Map<String, Object?>.from(e)));
      } catch (_) {
        // Bozuk tek hafta kaydı tüm ear-curriculum ilerlemesini silmesin.
      }
    }
    return out;
  }

  static List<EarSessionResult> _parseEarSessionHistory(Map<String, Object?> j) {
    final raw = j['earSessionHistory'];
    if (raw is! List) return const [];
    final out = <EarSessionResult>[];
    for (final e in raw) {
      if (e is! Map) continue;
      try {
        out.add(EarSessionResult.fromJson(Map<String, Object?>.from(e)));
      } catch (_) {
        // Bozuk tek seans kaydı tüm geçmişi silmesin.
      }
    }
    return out;
  }

  static CustomWorkout? _parseCustomWorkout(Map<String, Object?> j) {
    final raw = j['customWorkout'];
    if (raw is! Map) {
      return null;
    }
    try {
      return CustomWorkout.fromJson(Map<String, Object?>.from(raw));
    } catch (_) {
      return null;
    }
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
      if (e is! Map) continue;
      try {
        out.add(
          CompletedGoalRecord.fromJson(Map<String, Object?>.from(e)),
        );
      } catch (_) {
        // Bozuk tek kayıt tüm tamamlanan hedef listesini silmesin.
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
        if (val is! Map) continue;
        try {
          out[key] = ExerciseGoal.fromJson(
            Map<String, Object?>.from(val),
          );
        } catch (_) {
          // Bozuk tek hedef diğer egzersizlerin hedeflerini silmesin.
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
