import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../audio/wav_pcm.dart';
import 'app_sound_policy.dart';

final class UiChimeService {
  UiChimeService._();
  static final UiChimeService instance = UiChimeService._();

  final _player = AudioPlayer();
  Uint8List? _ok;
  Uint8List? _bad;

  /// ZIP: doğru = C5+E5, yanlış = A3.
  Future<void> play(bool ok) async {
    if (!AppSoundPolicy.instance.enabled) {
      return;
    }
    try {
      final wav = ok
          ? (_ok ??= _melody([(523.25, 0.09), (659.25, 0.11)]))
          : (_bad ??= _tone(220, 0.14));
      await _player.stop();
      await _player.play(BytesSource(wav));
    } catch (_) {}
  }

  static Uint8List _melody(List<(double hz, double seconds)> notes) {
    final total = notes.fold<double>(0, (s, n) => s + n.$2);
    final n = (WavPcm.sampleRate * total).ceil();
    final out = Float64List(n);
    var offset = 0;
    for (final note in notes) {
      final seg = (WavPcm.sampleRate * note.$2).toInt();
      final w = 2 * math.pi * note.$1 / WavPcm.sampleRate;
      for (var i = 0; i < seg && offset + i < n; i++) {
        final env = i < 24
            ? i / 24.0
            : (seg - i) / (seg * 0.4).clamp(8.0, seg.toDouble());
        out[offset + i] = math.sin(w * i) * 0.2 * env.clamp(0.0, 1.0);
      }
      offset += seg;
    }
    return WavPcm.mono16Wav(out);
  }

  static Uint8List _tone(double hz, double seconds) {
    final n = (WavPcm.sampleRate * seconds).toInt();
    final out = Float64List(n);
    final w = 2 * math.pi * hz / WavPcm.sampleRate;
    for (var i = 0; i < n; i++) {
      final env = i < 32
          ? i / 32.0
          : (n - i) / (n * 0.35).clamp(8.0, n.toDouble());
      out[i] = math.sin(w * i) * 0.22 * env.clamp(0.0, 1.0);
    }
    return WavPcm.mono16Wav(out);
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}
