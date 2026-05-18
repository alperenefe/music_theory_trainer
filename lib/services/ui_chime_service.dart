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

  Future<void> play(bool ok) async {
    if (!AppSoundPolicy.instance.enabled) {
      return;
    }
    try {
      final wav = ok
          ? (_ok ??= _tone(784, 0.085))
          : (_bad ??= _tone(196, 0.12));
      await _player.stop();
      await _player.play(BytesSource(wav));
    } catch (_) {}
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
