import 'dart:typed_data';

final class PitchFrame {
  const PitchFrame({
    required this.hz,
    required this.rms,
    this.pcm,
    this.sampleRate,
  });

  /// Cihazın kaba frekans tahmini (Android'de sıfır-geçiş). Doğru perde için
  /// [pcm] üzerinde YIN kullanın.
  final double hz;
  final double rms;

  /// Ham, tek kanallı ses (−1…1). Yalnızca ham veriyi gönderen platformlarda
  /// (Android) dolu; aksi hâlde null.
  final Float64List? pcm;
  final int? sampleRate;

  PitchFrame withHz(double newHz) =>
      PitchFrame(hz: newHz, rms: rms, pcm: pcm, sampleRate: sampleRate);

  static PitchFrame fromEvent(dynamic e) {
    if (e is Map) {
      final hzRaw = e['hz'];
      final rmsRaw = e['rms'];
      final hz = hzRaw is num ? hzRaw.toDouble() : double.parse('$hzRaw');
      final rms = rmsRaw is num
          ? rmsRaw.toDouble().clamp(0.0, 1.0)
          : 1.0;
      final rawPcm = e['pcm'];
      final sr = e['sampleRate'];
      return PitchFrame(
        hz: hz,
        rms: rms,
        pcm: rawPcm is Uint8List ? _decodePcm16(rawPcm) : null,
        sampleRate: sr is num ? sr.toInt() : null,
      );
    }
    if (e is num) {
      return PitchFrame(hz: e.toDouble(), rms: 1.0);
    }
    throw ArgumentError('pitch_stream: beklenmeyen olay: $e');
  }

  /// 16-bit little-endian PCM → −1…1 aralığında Float64.
  static Float64List _decodePcm16(Uint8List bytes) {
    final n = bytes.length ~/ 2;
    final out = Float64List(n);
    final bd = ByteData.sublistView(bytes);
    for (var i = 0; i < n; i++) {
      out[i] = bd.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }
}
