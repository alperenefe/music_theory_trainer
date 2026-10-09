import 'dart:math' as math;
import 'dart:typed_data';

import '../dsp/chord_detector.dart';
import '../dsp/strum_session.dart';
import '../models/chord_shape.dart';

/// Bir akor döngüsü egzersizinde her ölçüde DOĞRU akorun çalınıp çalınmadığını
/// kayıttan denetler (ölçü başlangıcından kısa süre sonraki pencere).
final class ProgressionReport {
  const ProgressionReport({required this.perBar, required this.matched});

  /// Ölçü başına sonuç (`null` = pencere kayıtta yok / yeterince sessiz).
  final List<ChordAnalysis?> perBar;
  final int matched;

  int get bars => perBar.length;
  double get fraction => bars == 0 ? 0 : matched / bars;
}

abstract final class ProgressionJudge {
  static ProgressionReport judge({
    required Float64List audio,
    required int sampleRate,
    required StrumSession session,
    required List<ChordShape> barChords,
    required double latencyMs,
    List<ChordShape>? candidates,
  }) {
    const fft = 16384;
    final det = ChordDetector(sampleRate: sampleRate, fftSize: fft);
    final cands = candidates ?? barChords.toSet().toList();
    final firstSlot = session.pattern.downSlots.isEmpty ? 0 : session.pattern.downSlots.first;
    final out = <ChordAnalysis?>[];
    var matched = 0;
    for (var b = 0; b < session.bars; b++) {
      final t0 = session.playStartMs + b * session.barMs + firstSlot * session.eighthMs;
      final endMs = t0 + math.max(0, latencyMs) + 80 + fft * 1000 / sampleRate;
      final end = (endMs * sampleRate / 1000).round();
      final start = end - fft;
      if (start < 0 || end > audio.length) {
        out.add(null);
        continue;
      }
      final spec = det.analyze(Float64List.sublistView(audio, start, end));
      if (spec.rms < 0.004) {
        out.add(null);
        continue;
      }
      final res = det.check(barChords[b % barChords.length], spec, candidates: cands);
      out.add(res);
      if (res.isMatch) matched++;
    }
    return ProgressionReport(perBar: out, matched: matched);
  }

  /// Ritim puanı (0–1) ile akor doğruluğunu (0–1) tek yıldıza çevirir.
  /// Akorlar yanlışsa ritim ne kadar iyi olursa olsun yüksek yıldız verilmez.
  static int stars({required double rhythmScore, required double chordFraction}) {
    final s = 0.4 * rhythmScore + 0.6 * chordFraction;
    final capped = chordFraction < 0.5 ? math.min(s, 0.39) : s;
    if (capped >= 0.85) return 3;
    if (capped >= 0.65) return 2;
    if (capped >= 0.4) return 1;
    return 0;
  }
}
