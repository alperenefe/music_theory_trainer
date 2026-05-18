final class PracticePrefs {
  static const int defaultPoolMinMidi = 40;
  static const int defaultPoolMaxMidi = 71;
  static const double defaultReferenceA4Hz = 440;

  const PracticePrefs({
    this.poolMinMidi = PracticePrefs.defaultPoolMinMidi,
    this.poolMaxMidi = PracticePrefs.defaultPoolMaxMidi,
    this.goalKind,
    this.goalTarget = 500,
    this.goalProgress = 0,
    this.goalStartedAtMillis = 0,
    this.soundEnabled = true,
    this.onboardingDone = false,
    this.referenceA4Hz = PracticePrefs.defaultReferenceA4Hz,
  });

  final int poolMinMidi;
  final int poolMaxMidi;
  final String? goalKind;
  final int goalTarget;
  final int goalProgress;
  final int goalStartedAtMillis;
  final bool soundEnabled;
  final bool onboardingDone;
  final double referenceA4Hz;

  PracticePrefs copyWith({
    int? poolMinMidi,
    int? poolMaxMidi,
    String? goalKind,
    bool clearGoal = false,
    int? goalTarget,
    int? goalProgress,
    int? goalStartedAtMillis,
    bool? soundEnabled,
    bool? onboardingDone,
    double? referenceA4Hz,
  }) {
    return PracticePrefs(
      poolMinMidi: poolMinMidi ?? this.poolMinMidi,
      poolMaxMidi: poolMaxMidi ?? this.poolMaxMidi,
      goalKind: clearGoal ? null : (goalKind ?? this.goalKind),
      goalTarget: goalTarget ?? this.goalTarget,
      goalProgress: goalProgress ?? this.goalProgress,
      goalStartedAtMillis: goalStartedAtMillis ?? this.goalStartedAtMillis,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      referenceA4Hz: referenceA4Hz ?? this.referenceA4Hz,
    );
  }

  Map<String, Object?> toJson() => {
    'poolMinMidi': poolMinMidi,
    'poolMaxMidi': poolMaxMidi,
    'goalKind': goalKind,
    'goalTarget': goalTarget,
    'goalProgress': goalProgress,
    'goalStartedAtMillis': goalStartedAtMillis,
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

    return PracticePrefs(
      poolMinMidi: ni(j['poolMinMidi'], defaultPoolMinMidi),
      poolMaxMidi: ni(j['poolMaxMidi'], defaultPoolMaxMidi),
      goalKind: j['goalKind'] as String?,
      goalTarget: ni(j['goalTarget'], 500),
      goalProgress: ni(j['goalProgress'], 0),
      goalStartedAtMillis: ni(j['goalStartedAtMillis'], 0),
      soundEnabled: soundEnabled,
      onboardingDone: onboardingDone,
      referenceA4Hz: ref,
    );
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
