import 'dart:math' as math;
import 'dart:typed_data';

/// Gitar teli sentezi — ALGILAMA testlerinde gerçekçi giriş sinyali üretmek için.
///
/// Perde/akor/vuruş algılayıcıları cihaz olmadan, bilinen bir gerçeğe (hangi
/// akor, hangi anda, kaç cent akortsuz çalındı) karşı doğrulanabilsin diye var.
/// Uyarı: bu sentetik bir sinyaldir; gerçek bir gitarın gövde rezonansı, oda
/// yankısı ve mikrofon karakteri burada yoktur.
abstract final class GuitarSynth {
  static double hzFromMidi(num midi, {double a4 = 440}) =>
      a4 * math.pow(2.0, (midi - 69) / 12.0);

  /// Toplamsal sentez: harmonikler tam olarak h·f0 (küçük bir inharmonisite ile),
  /// üst harmonikler daha hızlı söner, tel pozisyonuna bağlı tarak süzgeci ve
  /// kısa bir pena (pick) gürültüsü içerir. Frekans hassas biçimde kontrol edilir.
  static Float64List string({
    required double hz,
    required int sampleRate,
    double seconds = 1.0,
    double decaySeconds = 1.4,
    int harmonics = 10,
    double pluckPosition = 0.16,
    double inharmonicity = 0.00015,
    double pickNoise = 0.05,
    int seed = 1,
  }) {
    final n = (sampleRate * seconds).round();
    final out = Float64List(n);
    final rng = math.Random(seed);
    final nyquist = sampleRate / 2;
    for (var h = 1; h <= harmonics; h++) {
      final fh = h * hz * math.sqrt(1 + inharmonicity * h * h);
      if (fh >= nyquist * 0.95) break;
      final comb = 0.35 + 0.65 * math.sin(math.pi * h * pluckPosition).abs();
      final amp = comb / math.pow(h.toDouble(), 1.05);
      final tau = decaySeconds / (1 + 0.55 * (h - 1));
      final phase = rng.nextDouble() * 2 * math.pi;
      final w = 2 * math.pi * fh / sampleRate;
      for (var i = 0; i < n; i++) {
        out[i] += amp * math.exp(-i / sampleRate / tau) * math.sin(w * i + phase);
      }
    }
    // Pena gürültüsü: ilk ~8 ms'de hızla sönen geniş bantlı vuruş.
    final pickLen = (sampleRate * 0.008).round();
    for (var i = 0; i < pickLen && i < n; i++) {
      out[i] += pickNoise * (rng.nextDouble() * 2 - 1) * (1 - i / pickLen);
    }
    // Çok kısa giriş (tık sesini yumuşat) ve çıkışta yumuşak sönme: gerçek bir
    // tel aniden kesilmez; kesilen sentetik ses yapay bir "tık" üretir.
    final fade = math.min(24, n);
    for (var i = 0; i < fade; i++) {
      out[i] *= i / fade;
    }
    final fadeOut = math.min((sampleRate * 0.12).round(), n ~/ 3);
    for (var i = 0; i < fadeOut; i++) {
      out[n - 1 - i] *= i / fadeOut;
    }
    return out;
  }

  /// Uygulamanın kendi sentezinde kullanılan Karplus-Strong. Frekansı biraz
  /// kayabilir (özellikle tiz notalarda ~10 cent); testlerde "akortsuz gitar"
  /// senaryosu olarak kullanılır.
  static Float64List karplusStrong({
    required double hz,
    required int sampleRate,
    double seconds = 1.0,
    double damping = 0.498,
    int seed = 1,
  }) {
    final n = (sampleRate * seconds).round();
    final period = math.max(2, (sampleRate / hz).round());
    final rng = math.Random(seed);
    final buf = List<double>.generate(period, (_) => rng.nextDouble() * 2 - 1);
    final out = Float64List(n);
    for (var i = 0; i < n; i++) {
      final idx = i % period;
      out[i] = buf[idx];
      buf[idx] = (buf[idx] + buf[(idx + 1) % period]) * damping;
    }
    return out;
  }

  /// [midis] içindeki telleri [strumMs] aralıkla (pes tel önce) çalan akor.
  static Float64List chord({
    required List<int> midis,
    required int sampleRate,
    double seconds = 1.2,
    double strumMs = 18,
    double centsOffset = 0,
    bool karplus = false,
    int seed = 7,
    double a4 = 440,
  }) {
    final total = (sampleRate * seconds).round();
    final out = Float64List(total);
    final delay = (sampleRate * strumMs / 1000).round();
    for (var s = 0; s < midis.length; s++) {
      final hz = hzFromMidi(midis[s] + centsOffset / 100, a4: a4);
      final str = karplus
          ? karplusStrong(hz: hz, sampleRate: sampleRate, seconds: seconds, seed: seed + s * 31)
          : string(hz: hz, sampleRate: sampleRate, seconds: seconds, seed: seed + s * 31);
      final off = s * delay;
      for (var i = 0; i + off < total; i++) {
        out[i + off] += str[i];
      }
    }
    // Sonradan giren teller tampon sonunda kesildiği için tüm akora yumuşak
    // bir sönme uygula (aksi hâlde sentetik bir "tık" oluşur).
    final fadeOut = math.min((sampleRate * 0.12).round(), total ~/ 3);
    for (var i = 0; i < fadeOut; i++) {
      out[total - 1 - i] *= i / fadeOut;
    }
    normalize(out);
    return out;
  }

  /// Sinyali tepe değeri [peak] olacak şekilde ölçekler.
  static void normalize(Float64List x, {double peak = 0.8}) {
    var m = 0.0;
    for (final v in x) {
      final a = v.abs();
      if (a > m) m = a;
    }
    if (m <= 0) return;
    final k = peak / m;
    for (var i = 0; i < x.length; i++) {
      x[i] *= k;
    }
  }

  /// [signal]'a [snrDb] oranında beyaz gürültü ekler (RMS'ye göre).
  static Float64List addNoise(Float64List signal, double snrDb, {int seed = 3}) {
    var e = 0.0;
    for (final v in signal) {
      e += v * v;
    }
    final rms = math.sqrt(e / math.max(1, signal.length));
    final noiseRms = rms / math.pow(10.0, snrDb / 20.0);
    final rng = math.Random(seed);
    final out = Float64List(signal.length);
    for (var i = 0; i < signal.length; i++) {
      // Yaklaşık Gauss: 12 düzgün dağılımın toplamı.
      var g = 0.0;
      for (var k = 0; k < 12; k++) {
        g += rng.nextDouble();
      }
      g -= 6.0;
      out[i] = signal[i] + g * noiseRms;
    }
    return out;
  }

  /// [dst]'ye [src]'yi [offsetSample]'dan itibaren ekler.
  static void mixInto(Float64List dst, Float64List src, int offsetSample) {
    for (var i = 0; i < src.length; i++) {
      final j = offsetSample + i;
      if (j < 0 || j >= dst.length) continue;
      dst[j] += src[i];
    }
  }
}
