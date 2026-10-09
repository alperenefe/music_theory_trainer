import 'dart:math' as math;

abstract final class PitchFromHz {
  /// Gitar / akort: harmonikleri katlayıp en net MIDI eşleşmesini seç.
  static double refineForGuitar(double hz, {double referenceA4 = 440}) {
    if (!hz.isFinite || hz <= 0) {
      return hz;
    }
    var bestHz = hz;
    var bestCents = double.infinity;
    // Yalnızca oktav katları (×2 / ÷2); ×3 Re (D) yanılgısını azaltır.
    const factors = [1.0, 2.0, 4.0, 0.5, 0.25];
    for (final f in factors) {
      final c = hz * f;
      if (c < 70 || c > 520) {
        continue;
      }
      final midi = midiFromHz(c, referenceA4: referenceA4);
      if (midi == null) {
        continue;
      }
      final ref = hzFromMidi(midi, referenceA4);
      final cents = centsDelta(c, ref)?.abs() ?? double.infinity;
      final better = cents < bestCents - 0.5 ||
          (cents <= bestCents + 0.5 && c < bestHz);
      if (better) {
        bestCents = cents;
        // Katlanmış ama GERÇEK ölçülen frekansı (c) sakla — `ref` en yakın
        // yarım sese yuvarlanmış "kusursuz" frekanstır. `ref`'i döndürürsek
        // pesten/tizden ne kadar saptığı bilgisini burada siler, akort
        // ibresi/cents okuması her zaman ~0 gösterir (akort her zaman
        // "tam" görünür). Aynı düzeltme guitar_target_pitch_match.dart'taki
        // foldToFundamental'da doğru yapılıyor (bestHz = candidate).
        bestHz = c;
      }
    }
    return bestHz;
  }

  static int? midiFromHz(double hz, {double referenceA4 = 440}) {
    if (!hz.isFinite || hz <= 0) {
      return null;
    }
    if (hz < 70 || hz > 520) {
      return null;
    }
    final m = 69 + 12 * math.log(hz / referenceA4) / math.ln2;
    return m.round().clamp(0, 127);
  }

  static double hzFromMidi(int midi, double referenceA4) {
    return referenceA4 * math.pow(2.0, (midi - 69) / 12.0);
  }

  static double? centsDelta(double detectedHz, double referenceHz) {
    if (!detectedHz.isFinite || detectedHz <= 0) {
      return null;
    }
    if (!referenceHz.isFinite || referenceHz <= 0) {
      return null;
    }
    return 1200 * math.log(detectedHz / referenceHz) / math.ln2;
  }
}
