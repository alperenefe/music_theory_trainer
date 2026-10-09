import 'dart:math' as math;

/// Bir vuruşun beklenenle karşılaştırması.
enum StrumGrade {
  perfect, // ±[perfectMs]
  good, // ±[goodMs]
  early, // daha erken
  late, // daha geç
  missed, // karşılığında vuruş yok
}

final class StrumJudgement {
  const StrumJudgement({
    required this.expectedMs,
    required this.grade,
    this.errorMs,
  });

  final double expectedMs;
  final StrumGrade grade;

  /// Ortanca gecikme çıkarıldıktan sonraki sapma (+ = geç). `missed` ise null.
  final double? errorMs;
}

final class RhythmResult {
  const RhythmResult({
    required this.judgements,
    required this.extraHits,
    required this.latencyMs,
    required this.jitterMs,
  });

  final List<StrumJudgement> judgements;

  /// Beklenen bir vuruşla eşleşmeyen fazladan vuruşlar.
  final int extraHits;

  /// Tüm vuruşlardaki ortak sabit kayma (cihaz gecikmesi + alışılmış geç/erken
  /// çalma); ortanca. Bu, bireysel hatalardan ÇIKARILIR.
  final double latencyMs;

  /// Ortalama mutlak sapma — ritmin ne kadar "düzenli" olduğu.
  final double jitterMs;

  int count(StrumGrade g) => judgements.where((j) => j.grade == g).length;
  int get expected => judgements.length;
  int get hit => expected - count(StrumGrade.missed);

  /// 0–1. Mükemmel 1, iyi 0.7, erken/geç 0.35, kaçan 0; fazladan vuruşlar düşürür.
  double get score {
    if (expected == 0) return 0;
    var s = 0.0;
    for (final j in judgements) {
      s += switch (j.grade) {
        StrumGrade.perfect => 1.0,
        StrumGrade.good => 0.7,
        StrumGrade.early || StrumGrade.late => 0.35,
        StrumGrade.missed => 0.0,
      };
    }
    final penalty = math.min(0.3, extraHits * 0.04);
    return ((s / expected) - penalty).clamp(0.0, 1.0);
  }

  /// 0–3 yıldız.
  int get stars {
    final sc = score;
    if (sc >= 0.85) return 3;
    if (sc >= 0.65) return 2;
    if (sc >= 0.4) return 1;
    return 0;
  }
}

/// Çalınan vuruşları beklenen ızgarayla (metronom) karşılaştırır.
///
/// Cihazın ses giriş/çıkış gecikmesi bilinmediği için MUTLAK zamana güvenilmez:
/// tüm vuruşlar için ortak bir kayma ([RhythmResult.latencyMs]) kestirilir ve
/// çıkarılır; geri kalan sapma "ritim düzenliliğidir". Bu, gitaristin ne kadar
/// metronoma oturduğunu gecikmeden bağımsız ölçer.
abstract final class RhythmEvaluator {
  static RhythmResult evaluate({
    required List<double> expectedMs,
    required List<double> playedMs,
    List<double> optionalMs = const [],
    double perfectMs = 40,
    double goodMs = 80,
    double maxShiftMs = 250,
    double? matchWindowMs,
  }) {
    if (expectedMs.isEmpty) {
      return RhythmResult(
        judgements: const [],
        extraHits: playedMs.length,
        latencyMs: 0,
        jitterMs: 0,
      );
    }
    final window = matchWindowMs ?? _defaultWindow(expectedMs);

    // 1) Ortak kaymayı bul: eşleşen vuruş sayısını en çok yapan kayma
    // (eşitlikte toplam sapması en az olan).
    double bestShift = 0;
    var bestMatches = -1;
    var bestCost = double.infinity;
    // Kayma ararken DAR pencere kullan: geniş pencerede (kalıbın vuruş aralığının
    // %45'i) komşu yukarı vuruşlar da yanlış kaymalarda eşleşip tahmini kaydırır.
    final searchWindow = math.min(window, 100.0);
    for (var shift = -maxShiftMs; shift <= maxShiftMs; shift += 5) {
      final m = _match(expectedMs, playedMs, shift, searchWindow);
      final cost = m.totalAbsError;
      if (m.matches > bestMatches || (m.matches == bestMatches && cost < bestCost)) {
        bestMatches = m.matches;
        bestCost = cost;
        bestShift = shift;
      }
    }

    // 2) Kayma çevresinde ince ayar: eşleşen sapmaların ortancası.
    final first = _match(expectedMs, playedMs, bestShift, window);
    final errs = first.errors.nonNulls.toList();
    final latency = errs.isEmpty ? bestShift : _median(errs) + bestShift;
    final fine = _match(expectedMs, playedMs, latency, window);

    final judgements = <StrumJudgement>[];
    var absSum = 0.0;
    var n = 0;
    for (var i = 0; i < expectedMs.length; i++) {
      final err = fine.errors[i];
      if (err == null) {
        judgements.add(StrumJudgement(expectedMs: expectedMs[i], grade: StrumGrade.missed));
        continue;
      }
      final a = err.abs();
      absSum += a;
      n++;
      final grade = a <= perfectMs
          ? StrumGrade.perfect
          : a <= goodMs
              ? StrumGrade.good
              : (err < 0 ? StrumGrade.early : StrumGrade.late);
      judgements.add(StrumJudgement(expectedMs: expectedMs[i], grade: grade, errorMs: err));
    }
    // Yukarı vuruşlar sessiz ve ince olduğundan algılayıcı onları kaçırabilir:
    // çalındıysa "fazladan" sayılmaz, çalınmadıysa ceza verilmez.
    var extra = playedMs.length - fine.matches;
    if (optionalMs.isNotEmpty && extra > 0) {
      final used = List<bool>.filled(playedMs.length, false);
      for (final e in fine.matchedPlayedIndexes) {
        used[e] = true;
      }
      final optWindow = (window * 0.7).clamp(40.0, 120.0);
      for (final o in optionalMs) {
        var best = -1;
        var bestAbs = optWindow;
        for (var j = 0; j < playedMs.length; j++) {
          if (used[j]) continue;
          final d = (playedMs[j] - latency - o).abs();
          if (d <= bestAbs) {
            bestAbs = d;
            best = j;
          }
        }
        if (best >= 0) {
          used[best] = true;
          extra--;
        }
      }
    }
    return RhythmResult(
      judgements: judgements,
      extraHits: extra,
      latencyMs: latency,
      jitterMs: n == 0 ? 0 : absSum / n,
    );
  }

  static double _defaultWindow(List<double> expected) {
    if (expected.length < 2) return 150;
    var minGap = double.infinity;
    for (var i = 1; i < expected.length; i++) {
      minGap = math.min(minGap, expected[i] - expected[i - 1]);
    }
    return (minGap * 0.45).clamp(60.0, 200.0);
  }

  static double _median(List<double> v) {
    final s = [...v]..sort();
    final m = s.length ~/ 2;
    return s.length.isOdd ? s[m] : (s[m - 1] + s[m]) / 2;
  }

  /// Her beklenen vuruşu, [shift] uygulanmış en yakın ve henüz kullanılmamış
  /// çalınan vuruşla eşler.
  static _Match _match(
    List<double> expected,
    List<double> played,
    double shift,
    double window,
  ) {
    final used = List<bool>.filled(played.length, false);
    final errors = List<double?>.filled(expected.length, null);
    final matchedIdx = <int>[];
    var matches = 0;
    var total = 0.0;
    for (var i = 0; i < expected.length; i++) {
      var best = -1;
      var bestAbs = window;
      for (var j = 0; j < played.length; j++) {
        if (used[j]) continue;
        final e = played[j] - shift - expected[i];
        if (e.abs() <= bestAbs) {
          bestAbs = e.abs();
          best = j;
        }
      }
      if (best >= 0) {
        used[best] = true;
        matchedIdx.add(best);
        errors[i] = played[best] - shift - expected[i];
        matches++;
        total += bestAbs;
      }
    }
    return _Match(errors, matches, total, matchedIdx);
  }
}

final class _Match {
  const _Match(this.errors, this.matches, this.totalAbsError, this.matchedPlayedIndexes);
  final List<double?> errors;
  final List<int> matchedPlayedIndexes;
  final int matches;
  final double totalAbsError;
}
