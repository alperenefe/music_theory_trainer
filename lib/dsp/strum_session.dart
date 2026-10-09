import 'dart:math' as math;

import '../models/strum_pattern.dart';
import 'rhythm_evaluator.dart';

/// Bir vuruş egzersizinin zaman çizelgesi ve değerlendirmesi (UI'dan bağımsız).
///
/// Zaman çizelgesi (ms, parça başından): önce [countInBars] ölçü metronom
/// (çalma), ardından [bars] ölçü kalıp. Beklenen vuruşlar kalıbın aşağı
/// vuruşlarıdır; yukarı vuruşlar isteğe bağlıdır (sessiz oldukları için
/// algılayıcı kaçırabilir).
///
/// Hoparlör sızıntısı: metronom tıklaması mikrofona girip vuruş gibi
/// algılanabilir. Geri sayımda kullanıcı çalmadığı için, o ölçüdeki algılar
/// tıklama sızıntısıdır: tıklamaya göre gecikme ve güç imzası öğrenilir; ana
/// bölümde bu imzaya uyan ve ondan belirgin biçimde güçlü olmayan algılar
/// çıkarılır. (Kulaklık takılıysa sızıntı yoktur ve hiçbir şey çıkarılmaz.)
final class StrumSession {
  StrumSession({
    required this.pattern,
    required this.bpm,
    required this.bars,
    this.countInBars = 1,
    this.beatsPerBar = 4,
  });

  final StrumPattern pattern;
  final int bpm;
  final int bars;
  final int countInBars;
  final int beatsPerBar;

  double get beatMs => 60000.0 / bpm;
  double get eighthMs => beatMs / 2;
  double get barMs => beatMs * beatsPerBar;

  /// Toplam ölçü (geri sayım dahil).
  int get totalBars => countInBars + bars;

  double get totalMs => totalBars * barMs;
  double get playStartMs => countInBars * barMs;

  /// Metronom tıklamalarının zamanı (geri sayım dahil, her vuruşta bir tane).
  List<double> get clickTimesMs => [
        for (var i = 0; i < totalBars * beatsPerBar; i++) i * beatMs,
      ];

  List<double> _slotTimes(Iterable<int> slots) => [
        for (var b = 0; b < bars; b++)
          for (final s in slots) playStartMs + b * barMs + s * eighthMs,
      ];

  /// Zorunlu (aşağı) vuruşların beklenen zamanı.
  List<double> get expectedDownMs => _slotTimes(pattern.downSlots);

  /// İsteğe bağlı (yukarı) vuruşların beklenen zamanı.
  List<double> get expectedUpMs => _slotTimes(pattern.upSlots);

  /// Algılanan vuruşları ([onsetsMs]: parça başından ms, güçleriyle) süzüp
  /// değerlendirir.
  StrumReport evaluate(List<DetectedStrum> onsets) {
    final leak = _estimateLeak(onsets);
    final kept = <DetectedStrum>[];
    var leakRemoved = 0;
    for (final o in onsets) {
      // Geri sayımda çalınanlar çalışmanın parçası değildir.
      if (o.timeMs < playStartMs - eighthMs) continue;
      if (leak != null && leak.isLeak(o, clickTimesMs)) {
        leakRemoved++;
        continue;
      }
      kept.add(o);
    }
    final played = [for (final k in kept) k.timeMs]..sort();
    final r = RhythmEvaluator.evaluate(
      expectedMs: expectedDownMs,
      playedMs: played,
      optionalMs: expectedUpMs,
    );
    return StrumReport(
      result: r,
      leakDetected: leak != null,
      leakRemoved: leakRemoved,
      keptHits: kept.length,
    );
  }

  /// Geri sayımdaki algıların tıklamalara oranından sızıntı imzası çıkarır.
  _Leak? _estimateLeak(List<DetectedStrum> onsets) {
    final clicks = [for (final c in clickTimesMs) if (c < playStartMs) c];
    final during = [for (final o in onsets) if (o.timeMs < playStartMs) o];
    if (clicks.length < 3 || during.length < 2) return null;
    // Her algıyı en yakın sonraki tıklamaya eşle; gecikmelerin ortancası.
    final delays = <double>[];
    var maxStrength = 0.0;
    for (final o in during) {
      double? best;
      for (final c in clicks) {
        final d = o.timeMs - c;
        if (d >= -20 && d <= 300 && (best == null || d.abs() < best.abs())) best = d;
      }
      if (best != null) {
        delays.add(best);
        maxStrength = math.max(maxStrength, o.strength);
      }
    }
    if (delays.length < 2) return null;
    delays.sort();
    final median = delays[delays.length ~/ 2];
    final spread = delays.last - delays.first;
    // Düzenli (aynı gecikmeyle tekrar eden) bir iz yoksa sızıntı değildir:
    // kullanıcı geri sayımda erken çalmaya başlamış olabilir.
    if (spread > 60) return null;
    return _Leak(delayMs: median, maxStrength: maxStrength);
  }
}

/// Algılanan bir vuruş (parça başına göre ms) ve gücü.
final class DetectedStrum {
  const DetectedStrum(this.timeMs, this.strength);
  final double timeMs;
  final double strength;
}

final class StrumReport {
  const StrumReport({
    required this.result,
    required this.leakDetected,
    required this.leakRemoved,
    required this.keptHits,
  });

  final RhythmResult result;
  final bool leakDetected;
  final int leakRemoved;
  final int keptHits;
}

final class _Leak {
  const _Leak({required this.delayMs, required this.maxStrength});

  final double delayMs;
  final double maxStrength;

  /// Bir tıklama + sızıntı gecikmesine yakın VE tıklamanın tipik gücünden
  /// belirgin güçlü olmayan vuruş sızıntıdır. Gerçek bir strum tıklamayla
  /// çakışsa bile toplam enerji daha yüksek olduğundan ayrışır.
  bool isLeak(DetectedStrum o, List<double> clicks) {
    for (final c in clicks) {
      if ((o.timeMs - (c + delayMs)).abs() <= 45) {
        return o.strength <= maxStrength * 1.3;
      }
    }
    return false;
  }
}
