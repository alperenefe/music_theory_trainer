import 'dart:io';
import 'dart:typed_data';

/// Yalnız geliştirme: mikrofondan gelen son birkaç saniyeyi WAV olarak saklar,
/// gerçek cihazdaki algılama sorunlarını bilgisayarda aynı kodla yeniden
/// çalıştırıp incelemek için. Ses yalnızca uygulamanın geçici klasörüne yazılır.
final class DiagRecorder {
  DiagRecorder({this.seconds = 6});

  final int seconds;
  Float64List? _ring;
  var _rate = 44100;
  var _pos = 0;
  var _filled = 0;

  bool get hasAudio => _filled > 0;

  void add(Float64List samples, int sampleRate) {
    _rate = sampleRate;
    final ring = _ring ??= Float64List(seconds * sampleRate);
    for (final v in samples) {
      ring[_pos] = v;
      _pos = (_pos + 1) % ring.length;
    }
    _filled = (_filled + samples.length).clamp(0, ring.length);
  }

  /// WAV dosyasını yazar ve yolunu döner (`null` = kayıt yok).
  Future<String?> save(String tag) async {
    final ring = _ring;
    if (ring == null || _filled == 0) return null;
    final n = _filled;
    final start = (_pos - n) % ring.length;
    final bd = ByteData(44 + n * 2);
    void ascii(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        bd.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bd.setUint32(4, 36 + n * 2, Endian.little);
    ascii(8, 'WAVEfmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, _rate, Endian.little);
    bd.setUint32(28, _rate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    ascii(36, 'data');
    bd.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = ring[(start + i) % ring.length].clamp(-1.0, 1.0);
      bd.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    final f = File('${Directory.systemTemp.path}/diag_${tag}_${DateTime.now().millisecondsSinceEpoch}.wav');
    await f.writeAsBytes(bd.buffer.asUint8List());
    return f.path;
  }
}
