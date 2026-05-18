import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

import '../audio/wav_pcm.dart';
import 'app_sound_policy.dart';

final class GuitarAudioService {
  GuitarAudioService._();
  static final GuitarAudioService instance = GuitarAudioService._();

  final _player = AudioPlayer();
  final _cache = <int, Uint8List>{};

  Future<void> playMidi(int midi) async {
    if (!AppSoundPolicy.instance.enabled) {
      return;
    }
    try {
      final wav = _cache[midi] ??= _synthesize(midi);
      await _player.stop();
      await _player.play(BytesSource(wav));
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _player.dispose();
    _cache.clear();
  }

  static Uint8List _synthesize(int midi) {
    final freq = 440.0 * math.pow(2.0, (midi - 69) / 12.0);
    const durationSec = 1.8;
    final n = (WavPcm.sampleRate * durationSec).toInt();
    final period = (WavPcm.sampleRate / freq).round().clamp(4, 4096);

    final rng = math.Random(midi);
    final buf = List<double>.generate(period, (_) => rng.nextDouble() * 2 - 1);
    final out = Float64List(n);
    const damping = 0.4982;

    for (var i = 0; i < n; i++) {
      final idx = i % period;
      out[i] = buf[idx];
      buf[idx] = (buf[idx] + buf[(idx + 1) % period]) * damping;
    }

    const fadeIn = 64;
    for (var i = 0; i < fadeIn && i < n; i++) {
      out[i] *= i / fadeIn;
    }

    return WavPcm.mono16Wav(out);
  }
}
