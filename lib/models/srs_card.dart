/// SM-2 Spaced Repetition kart modeli.
/// Her nota için ayrı bir kart tutulur.
/// Kaynak: https://www.supermemo.com/en/archives1990-2015/english/ol/sm2
final class SrsCard {
  const SrsCard({
    required this.midi,
    this.easeFactor = 2.5,
    this.intervalDays = 1,
    this.repetitionCount = 0,
    this.nextReviewAt = 0,
  });

  final int midi;

  /// Kolaylık faktörü (başlangıç 2.5, minimum 1.3).
  final double easeFactor;

  /// Sonraki tekrara kaç gün.
  final int intervalDays;

  /// Başarılı tekrar sayısı (sıfırlanınca interval resetlenir).
  final int repetitionCount;

  /// Tekrar zamanı — epoch millisaniye.
  final int nextReviewAt;

  /// Bugün tekrar edilmesi gerekiyor mu?
  bool get isDueNow =>
      DateTime.now().millisecondsSinceEpoch >= nextReviewAt;

  /// SM-2 algoritmasına göre kart güncelle.
  /// [correct]: cevap doğru mu?
  /// [latencyMs]: tepki süresi (hız faktörü için).
  SrsCard update({required bool correct, required int latencyMs}) {
    // Kalite notu (0–5)
    final q = _qualityRating(correct: correct, latencyMs: latencyMs);

    // Yeni EF
    var newEF = easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (newEF < 1.3) newEF = 1.3;

    final now = DateTime.now().millisecondsSinceEpoch;

    if (q < 3) {
      // Yanlış cevap — sıfırla
      return SrsCard(
        midi: midi,
        easeFactor: newEF,
        intervalDays: 1,
        repetitionCount: 0,
        nextReviewAt: now + const Duration(days: 1).inMilliseconds,
      );
    }

    // Doğru cevap — interval hesapla
    final newRep = repetitionCount + 1;
    final int newInterval;
    if (newRep == 1) {
      newInterval = 1;
    } else if (newRep == 2) {
      newInterval = 6;
    } else {
      newInterval = (intervalDays * newEF).round().clamp(1, 365);
    }

    return SrsCard(
      midi: midi,
      easeFactor: newEF,
      intervalDays: newInterval,
      repetitionCount: newRep,
      nextReviewAt: now + Duration(days: newInterval).inMilliseconds,
    );
  }

  static int _qualityRating({required bool correct, required int latencyMs}) {
    if (!correct) return 1;
    if (latencyMs < 2500) return 5;
    if (latencyMs < 5000) return 4;
    return 3;
  }

  Map<String, Object?> toJson() => {
    'midi': midi,
    'easeFactor': easeFactor,
    'intervalDays': intervalDays,
    'repetitionCount': repetitionCount,
    'nextReviewAt': nextReviewAt,
  };

  static SrsCard fromJson(Map<String, Object?> j) {
    double nd(Object? v, double d) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is num) return v.toDouble();
      return d;
    }

    int ni(Object? v, int d) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return d;
    }

    return SrsCard(
      midi: ni(j['midi'], 0),
      easeFactor: nd(j['easeFactor'], 2.5),
      intervalDays: ni(j['intervalDays'], 1),
      repetitionCount: ni(j['repetitionCount'], 0),
      nextReviewAt: ni(j['nextReviewAt'], 0),
    );
  }
}
