import 'dart:math' as math;
import 'dart:typed_data';

/// Bir egzersizin tamamı için önceden üretilmiş metronom sesi (WAV).
///
/// Döngü yerine egzersizin TÜM süresi tek seferde üretilir: böylece döngü
/// sınırındaki küçük boşluklar olmaz ve her tıklamanın zamanı (ms) tam olarak
/// bilinir. Bu zamanlar, algılanan vuruşları değerlendirmek için ızgara olur.
final class MetronomeTrack {
  MetronomeTrack._(this.wav, this.clickTimesMs, this.bpm, this.beatsPerBar, this.totalBars);

  final Uint8List wav;

  /// Her tıklamanın parça başından itibaren zamanı (ms), vuruş sırasıyla.
  final List<double> clickTimesMs;
  final int bpm;
  final int beatsPerBar;
  final int totalBars;

  double get beatMs => 60000.0 / bpm;
  double get totalMs => totalBars * beatsPerBar * beatMs;

  static const sampleRate = 22050;

  /// [totalBars] ölçülük, ilk vuruşu vurgulu bir metronom parçası.
  /// [clickGain] 0–1: hoparlörden mikrofona sızmayı azaltmak için kısılabilir.
  static MetronomeTrack generate({
    required int bpm,
    required int totalBars,
    int beatsPerBar = 4,
    double clickGain = 0.7,
    double tailSeconds = 1.0,
  }) {
    final beatSamples = sampleRate * 60.0 / bpm;
    final n = (beatSamples * beatsPerBar * totalBars + sampleRate * tailSeconds).round();
    final out = Float64List(n);
    final times = <double>[];
    for (var i = 0; i < beatsPerBar * totalBars; i++) {
      final accent = i % beatsPerBar == 0;
      final start = (i * beatSamples).round();
      times.add(start * 1000 / sampleRate);
      _click(out, start, accent ? 1.0 : 0.75, accent ? 1100 : 820, clickGain);
    }
    return MetronomeTrack._(_wav(out), times, bpm, beatsPerBar, totalBars);
  }

  /// Yumuşak başlangıçlı, alçak frekanslı bir "tok" tıklama.
  ///
  /// Neden: vuruş algılayıcı 1.5–9 kHz bandında pena geçişi arar. Keskin
  /// başlangıçlı (süreksiz) bir tıklama geniş bantlı bir çıtırtıdır ve
  /// hoparlörden mikrofona sızınca gerçek bir vuruştan DAHA güçlü algılanır
  /// (ölçüldü: tıklama 46–188, strum 26–33). 4 ms'lik yarım kosinüs atak ve
  /// ≤1.1 kHz taşıyıcı, enerjiyi algılayıcının bandının altında tutar.
  static void _click(Float64List out, int start, double level, double hz, double gain) {
    final len = (sampleRate * 0.045).round();
    final attack = (sampleRate * 0.004).round();
    for (var i = 0; i < len && start + i < out.length; i++) {
      final t = i / sampleRate;
      final env = i < attack
          ? 0.5 - 0.5 * math.cos(math.pi * i / attack)
          : math.exp(-(i - attack) / sampleRate * 90);
      out[start + i] += math.sin(2 * math.pi * hz * t) * env * level * gain;
    }
  }

  static Uint8List _wav(Float64List samples) {
    final n = samples.length;
    final bytes = n * 2;
    final bd = ByteData(44 + bytes);
    void ascii(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        bd.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bd.setUint32(4, 36 + bytes, Endian.little);
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bd.setUint32(40, bytes, Endian.little);
    for (var i = 0; i < n; i++) {
      bd.setInt16(44 + i * 2, (samples[i].clamp(-1.0, 1.0) * 32767).round(), Endian.little);
    }
    return bd.buffer.asUint8List();
  }
}
