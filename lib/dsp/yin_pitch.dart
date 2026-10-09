import 'dart:math' as math;
import 'dart:typed_data';

final class PitchEstimate {
  const PitchEstimate({required this.hz, required this.clarity});

  final double hz;

  /// 0–1. 1'e yakın = net, periyodik (perdeli) ses; düşük = gürültü / perdesiz.
  final double clarity;
}

/// YIN (de Cheveigné & Kawahara, 2002) temel frekans tahmincisi.
///
/// Sıfır geçiş saymanın aksine harmonikler baskın olsa bile (gitarın pes
/// tellerinde sık görülür) doğru temel frekansı (oktav hatası olmadan) bulur.
final class YinPitchDetector {
  YinPitchDetector({
    required this.sampleRate,
    this.minHz = 60,
    this.maxHz = 1200,
    this.threshold = 0.15,
    this.minClarity = 0.6,
  });

  final int sampleRate;
  final double minHz;
  final double maxHz;

  /// Mutlak eşik: bunun altına inen ilk yerel minimum temel periyot sayılır.
  final double threshold;

  /// Tahmin bu netliğin altındaysa `null` döner.
  final double minClarity;

  /// En az `sampleRate / minHz * 2` örnek gerekir; daha kısaysa `null`.
  PitchEstimate? detect(Float64List samples) {
    final tauMax = (sampleRate / minHz).floor();
    final tauMin = math.max(2, (sampleRate / maxHz).floor());
    final w = samples.length - tauMax;
    if (w < tauMax ~/ 2 || tauMax <= tauMin + 2) return null;

    // Fark fonksiyonu d(tau).
    final d = Float64List(tauMax + 1);
    for (var tau = 1; tau <= tauMax; tau++) {
      var sum = 0.0;
      for (var j = 0; j < w; j++) {
        final diff = samples[j] - samples[j + tau];
        sum += diff * diff;
      }
      d[tau] = sum;
    }

    // Kümülatif ortalama normalize fark d'(tau).
    final dn = Float64List(tauMax + 1);
    dn[0] = 1;
    var running = 0.0;
    for (var tau = 1; tau <= tauMax; tau++) {
      running += d[tau];
      dn[tau] = running == 0 ? 1.0 : d[tau] * tau / running;
    }

    // Mutlak eşiğin altına ilk inen yerel minimum.
    var tauEst = -1;
    for (var tau = tauMin; tau < tauMax; tau++) {
      if (dn[tau] < threshold) {
        while (tau + 1 < tauMax && dn[tau + 1] < dn[tau]) {
          tau++;
        }
        tauEst = tau;
        break;
      }
    }
    if (tauEst < 0) {
      // Eşik altı yoksa en küçük minimumu al (düşük netlikle).
      var best = tauMin;
      for (var tau = tauMin; tau < tauMax; tau++) {
        if (dn[tau] < dn[best]) best = tau;
      }
      tauEst = best;
    }

    final clarity = (1 - dn[tauEst]).clamp(0.0, 1.0);
    if (clarity < minClarity) return null;

    // Parabolik interpolasyon (alt örnek hassasiyeti).
    double better = tauEst.toDouble();
    if (tauEst > 1 && tauEst < tauMax) {
      final s0 = dn[tauEst - 1];
      final s1 = dn[tauEst];
      final s2 = dn[tauEst + 1];
      final denom = 2 * (2 * s1 - s2 - s0);
      if (denom.abs() > 1e-12) {
        better = tauEst + (s2 - s0) / denom;
      }
    }
    final hz = sampleRate / better;
    if (hz < minHz || hz > maxHz) return null;
    return PitchEstimate(hz: hz, clarity: clarity);
  }
}
