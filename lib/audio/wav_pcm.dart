import 'dart:typed_data';

abstract final class WavPcm {
  static const sampleRate = 22050;

  static Uint8List mono16Wav(Float64List samples) {
    final n = samples.length;
    final pcmBytes = n * 2;
    final total = 44 + pcmBytes;
    final bd = ByteData(total);

    void ascii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        bd.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    bd.setUint32(4, 36 + pcmBytes, Endian.little);
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
    bd.setUint32(40, pcmBytes, Endian.little);

    for (var i = 0; i < n; i++) {
      final v = (samples[i] * 32767).clamp(-32767.0, 32767.0).toInt();
      bd.setInt16(44 + i * 2, v, Endian.little);
    }

    return bd.buffer.asUint8List();
  }
}
