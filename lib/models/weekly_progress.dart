final class WeeklyProgress {
  const WeeklyProgress({
    required this.weekNumber,
    this.isUnlocked = false,
    this.isCompleted = false,
    this.bestAccuracy = 0.0,
    this.totalQuestions = 0,
    this.totalCorrect = 0,
    this.unlockedAt,
    this.completedAt,
    this.errorsBySubtype = const {},
    this.activeDays = const [],
    this.bossCleared = false,
    this.confidence,
    this.hardestArea,
    this.lessonViewed = false,
    this.recentAccuracies = const [],
  });

  /// Baraj doğruluğu bu kadar son turun ortalamasıdır.
  static const gateWindow = 3;
  static const _maxRecent = 5;

  final int weekNumber;
  final bool isUnlocked;
  final bool isCompleted;

  /// Tek bir seansta ulaşılan en yüksek doğruluk (0–1).
  final double bestAccuracy;
  final int totalQuestions;
  final int totalCorrect;
  final DateTime? unlockedAt;
  final DateTime? completedAt;
  final Map<String, int> errorsBySubtype;

  /// Bu haftaya pratik yapılan farklı günler (yyyy-MM-dd) — dağıtılmış pratik barajı.
  final List<String> activeDays;

  /// Haftanın boss meydan okuması geçildi mi.
  final bool bossCleared;

  /// Haftalık öz değerlendirme: 1–5 güven puanı.
  final int? confidence;

  /// Haftalık öz değerlendirme: en çok zorlanılan alan.
  final String? hardestArea;

  /// [EarLessonScreen] en az bir kez açıldı mı — "Dersi Oku" kartında
  /// tamamlandı rozeti göstermek için.
  final bool lessonViewed;

  /// Baraja sayılan son turların doğrulukları (eskiden yeniye, en fazla 5).
  final List<double> recentAccuracies;

  double get accuracy =>
      totalQuestions == 0 ? 0.0 : totalCorrect / totalQuestions;

  /// Barajda kullanılan doğruluk: son [gateWindow] turun ortalaması.
  /// Tek bir şanslı tur barajı geçirmesin diye en iyi tura değil ortalamaya
  /// bakılır. Bu alan eklenmeden önce kaydedilmiş haftalarda liste boştur;
  /// o zaman eski davranış (en iyi tur) korunur.
  double get gateAccuracy {
    if (recentAccuracies.isEmpty) return bestAccuracy;
    final window = recentAccuracies.length <= gateWindow
        ? recentAccuracies
        : recentAccuracies.sublist(recentAccuracies.length - gateWindow);
    return window.reduce((a, b) => a + b) / window.length;
  }

  /// Yeni bir tur doğruluğu eklenmiş liste (en fazla 5 kayıt tutulur).
  List<double> withRecentAccuracy(double acc) {
    final next = [...recentAccuracies, acc];
    return next.length <= _maxRecent ? next : next.sublist(next.length - _maxRecent);
  }

  bool get hasReflection => confidence != null;

  static String dayKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  WeeklyProgress copyWith({
    int? weekNumber,
    bool? isUnlocked,
    bool? isCompleted,
    double? bestAccuracy,
    int? totalQuestions,
    int? totalCorrect,
    DateTime? unlockedAt,
    DateTime? completedAt,
    Map<String, int>? errorsBySubtype,
    List<String>? activeDays,
    bool? bossCleared,
    int? confidence,
    String? hardestArea,
    bool? lessonViewed,
    List<double>? recentAccuracies,
  }) {
    return WeeklyProgress(
      weekNumber: weekNumber ?? this.weekNumber,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isCompleted: isCompleted ?? this.isCompleted,
      bestAccuracy: bestAccuracy ?? this.bestAccuracy,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalCorrect: totalCorrect ?? this.totalCorrect,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      completedAt: completedAt ?? this.completedAt,
      errorsBySubtype: errorsBySubtype ?? this.errorsBySubtype,
      activeDays: activeDays ?? this.activeDays,
      bossCleared: bossCleared ?? this.bossCleared,
      confidence: confidence ?? this.confidence,
      hardestArea: hardestArea ?? this.hardestArea,
      lessonViewed: lessonViewed ?? this.lessonViewed,
      recentAccuracies: recentAccuracies ?? this.recentAccuracies,
    );
  }

  Map<String, Object?> toJson() => {
        'weekNumber': weekNumber,
        'isUnlocked': isUnlocked,
        'isCompleted': isCompleted,
        'bestAccuracy': bestAccuracy,
        'totalQuestions': totalQuestions,
        'totalCorrect': totalCorrect,
        'unlockedAt': unlockedAt?.millisecondsSinceEpoch,
        'completedAt': completedAt?.millisecondsSinceEpoch,
        'errorsBySubtype': errorsBySubtype,
        'activeDays': activeDays,
        'bossCleared': bossCleared,
        if (confidence != null) 'confidence': confidence,
        if (hardestArea != null) 'hardestArea': hardestArea,
        if (lessonViewed) 'lessonViewed': lessonViewed,
        if (recentAccuracies.isNotEmpty) 'recentAccuracies': recentAccuracies,
      };

  static WeeklyProgress fromJson(Map<String, Object?> j) {
    int ni(Object? v, int d) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return d;
    }

    double nd(Object? v, double d) {
      if (v is num) return v.toDouble();
      return d;
    }

    final rawErr = j['errorsBySubtype'];
    final errors = <String, int>{};
    if (rawErr is Map) {
      for (final e in rawErr.entries) {
        errors[e.key.toString()] = ni(e.value, 0);
      }
    }

    final rawDays = j['activeDays'];
    final days = <String>[
      if (rawDays is List)
        for (final d in rawDays)
          if (d is String && d.isNotEmpty) d,
    ];

    final rawRecent = j['recentAccuracies'];
    final recent = <double>[
      if (rawRecent is List)
        for (final a in rawRecent)
          if (a is num) a.toDouble().clamp(0.0, 1.0),
    ];

    final unlEpoch = j['unlockedAt'];
    final compEpoch = j['completedAt'];
    final conf = j['confidence'];
    final hardest = j['hardestArea'];

    return WeeklyProgress(
      weekNumber: ni(j['weekNumber'], 1),
      isUnlocked: j['isUnlocked'] == true,
      isCompleted: j['isCompleted'] == true,
      bestAccuracy: nd(j['bestAccuracy'], 0.0),
      totalQuestions: ni(j['totalQuestions'], 0),
      totalCorrect: ni(j['totalCorrect'], 0),
      unlockedAt: unlEpoch is num
          ? DateTime.fromMillisecondsSinceEpoch(unlEpoch.toInt())
          : null,
      completedAt: compEpoch is num
          ? DateTime.fromMillisecondsSinceEpoch(compEpoch.toInt())
          : null,
      errorsBySubtype: errors,
      activeDays: days,
      bossCleared: j['bossCleared'] == true,
      confidence: conf is num ? conf.toInt().clamp(1, 5) : null,
      hardestArea: hardest is String && hardest.isNotEmpty ? hardest : null,
      lessonViewed: j['lessonViewed'] == true,
      recentAccuracies: recent,
    );
  }
}
