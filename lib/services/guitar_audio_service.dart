import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../audio/ear_audio_types.dart';
import '../audio/ear_sound.dart';
import '../audio/wav_pcm.dart';
import 'app_sound_policy.dart';

/// Karplus-Strong ile sentezlenen gitar sesleri.
///
/// Her üst düzey çalma çağrısı yeni bir "dizi" başlatır; önceki dizi (ör. yarım
/// kalmış kadans) bir sonraki adımına geçmeden iptal olur. Böylece "Tekrar dinle"
/// hızlı basıldığında akorlar birbirine karışmaz. Döndürülen Future, ses
/// kabaca duyulur biçimde bittiğinde tamamlanır (UI'daki "çalıyor" durumu için).
final class GuitarAudioService {
  GuitarAudioService._();
  static final GuitarAudioService instance = GuitarAudioService._();

  static const _noteRing = Duration(milliseconds: 900);
  static const _chordRing = Duration(milliseconds: 1300);

  AudioPlayer? _playerOrNull;
  final _cache = <String, Uint8List>{};
  int _sequence = 0;

  /// Oyuncu yalnızca ses gerçekten çalınacağı zaman oluşturulur
  /// (ses kapalıyken/testlerde platform kanalına dokunulmaz).
  AudioPlayer get _player => _playerOrNull ??= AudioPlayer();

  bool get _enabled => AppSoundPolicy.instance.enabled;

  /// Çalan diziyi durdurur (ör. egzersiz ekranından çıkarken).
  Future<void> stop() async {
    _sequence++;
    final p = _playerOrNull;
    if (p == null) return;
    try {
      await p.stop();
    } catch (e) {
      debugPrint('GuitarAudioService.stop failed: $e');
    }
  }

  /// [awaitRing] true ise Future ses duyulur biçimde bitince tamamlanır;
  /// false ise son nota/akor başladığı anda döner (eski `playMidi` davranışı —
  /// gam/perde egzersizleri buna güvenir).
  ///
  /// [referenceA4] hangi A4 frekansına (Hz) göre sentezleneceğini belirler.
  /// Kulak eğitimi her zaman standart 440Hz kullanır; gitar akort/perde
  /// egzersizleri kullanıcının ayarladığı referansı (`PracticePrefs.referenceA4Hz`)
  /// geçirmeli — aksi halde çalınan referans sesle mikrofonun beklediği
  /// referans uyuşmaz.
  Future<void> playSound(
    EarSound sound, {
    bool awaitRing = true,
    double referenceA4 = 440.0,
  }) async {
    if (!_enabled) return;
    final token = ++_sequence;
    final ring = awaitRing ? _ring : _noRing;
    switch (sound) {
      case NoteSound(:final midi):
        await _note(midi, token, referenceA4: referenceA4);
        await ring(token, _noteRing);
      case IntervalSound(:final rootMidi, :final interval, :final harmonic, :final descending):
        if (harmonic) {
          // Oktav (12 yarım ses) birlikte çalındığında iki nota psikoakustik
          // olarak çok güçlü füzyona uğrar (aynı perde sınıfı + üst
          // harmonikler çakışır) ve öğrenciye "iki nota" değil "tek, kalın
          // bir ton" gibi duyulabilir. Diğer aralıklarda bu sorun yok. Küçük
          // bir vuruş gecikmesi (strumDelay) iki ayrı atak (onset) sesini
          // duyulur kılar — ikisi hâlâ "birlikte" hissettirir ama artık
          // oktava özgü o dolgun/çift katmanlı karakteri net duyabilirsin.
          final strumDelayMs = interval.semitones == 12 ? 34.0 : 6.0;
          await _chord(
            [rootMidi, rootMidi + interval.semitones],
            token,
            strumDelayMs: strumDelayMs,
            referenceA4: referenceA4,
          );
          await ring(token, _chordRing);
        } else {
          final top = rootMidi + interval.semitones;
          await _note(descending ? top : rootMidi, token, referenceA4: referenceA4);
          if (!await _wait(token, const Duration(milliseconds: 650))) return;
          await _note(descending ? rootMidi : top, token, referenceA4: referenceA4);
          await ring(token, _noteRing);
        }
      case ChordSound(:final midis, :final arpeggio):
        await _chord(
          midis,
          token,
          strumDelayMs: arpeggio ? 260 : 28,
          referenceA4: referenceA4,
        );
        await ring(
          token,
          arpeggio
              ? Duration(milliseconds: 260 * (midis.length - 1)) + _noteRing
              : _chordRing,
        );
      case CadenceSound(:final chordMidis):
        for (var i = 0; i < chordMidis.length; i++) {
          if (token != _sequence) return;
          await _chord(chordMidis[i], token, referenceA4: referenceA4);
          final last = i == chordMidis.length - 1;
          if (!await _wait(token, last ? _chordRing : const Duration(milliseconds: 1050))) {
            return;
          }
        }
      case ScaleSound(:final notes, :final stepDurationMs):
        for (var i = 0; i < notes.length; i++) {
          if (token != _sequence) return;
          await _note(notes[i], token, referenceA4: referenceA4);
          final last = i == notes.length - 1;
          if (!await _wait(
            token,
            last ? _noteRing : Duration(milliseconds: stepDurationMs),
          )) {
            return;
          }
        }
      case HarmonicRhythmSound(:final chords, :final beatsPerChord, :final bpm):
        final beatMs = (60000 / bpm).round();
        final chordDurationMs = beatMs * beatsPerChord;
        for (var i = 0; i < chords.length; i++) {
          if (token != _sequence) return;
          await _chord(chords[i], token, strumDelayMs: 24, referenceA4: referenceA4);
          final last = i == chords.length - 1;
          if (!await _wait(
            token,
            last ? _chordRing : Duration(milliseconds: chordDurationMs),
          )) {
            return;
          }
        }
      case SlashChordSound(:final allMidis, :final arpeggio):
        await _chord(
          allMidis,
          token,
          strumDelayMs: arpeggio ? 240 : 32,
          referenceA4: referenceA4,
        );
        await ring(
          token,
          arpeggio
              ? Duration(milliseconds: 240 * (allMidis.length - 1)) + _noteRing
              : _chordRing,
        );
    }
  }

  // --- Geriye dönük uyumlu kısa yollar -------------------------------------

  /// Notayı başlatır ve hemen döner (çınlamayı beklemez).
  Future<void> playMidi(int midi, {double referenceA4 = 440.0}) =>
      playSound(NoteSound(midi), awaitRing: false, referenceA4: referenceA4);

  Future<void> playChordQuality(
    int rootMidi,
    EarChordQuality quality, {
    double referenceA4 = 440.0,
  }) =>
      playSound(
        ChordSound(rootMidi: rootMidi, quality: quality),
        awaitRing: false,
        referenceA4: referenceA4,
      );

  Future<void> playInterval(
    int rootMidi,
    EarIntervalType interval, {
    bool harmonic = false,
    double referenceA4 = 440.0,
  }) =>
      playSound(
        IntervalSound(rootMidi: rootMidi, interval: interval, harmonic: harmonic),
        awaitRing: false,
        referenceA4: referenceA4,
      );

  Future<void> playCadence(
    int rootMidi,
    EarCadenceType cadence, {
    double referenceA4 = 440.0,
  }) =>
      playSound(
        CadenceSound(rootMidi: rootMidi, cadence: cadence),
        awaitRing: false,
        referenceA4: referenceA4,
      );

  Future<void> dispose() async {
    _sequence++;
    await _playerOrNull?.dispose();
    _playerOrNull = null;
    _cache.clear();
  }

  // --- İç yardımcılar -------------------------------------------------------

  Future<void> _note(int midi, int token, {double referenceA4 = 440.0}) async {
    if (token != _sequence) return;
    try {
      final key = 'm_${midi}_${referenceA4.toStringAsFixed(1)}';
      final wav = _cache[key] ??= _synthesize(midi, referenceA4: referenceA4);
      await _player.stop();
      if (token != _sequence) return;
      await _player.play(BytesSource(wav));
    } catch (e, st) {
      debugPrint('GuitarAudioService note failed: $e\n$st');
    }
  }

  Future<void> _chord(
    List<int> midis,
    int token, {
    double strumDelayMs = 28,
    double referenceA4 = 440.0,
  }) async {
    if (token != _sequence || midis.isEmpty) return;
    try {
      final key =
          'c_${strumDelayMs.round()}_${referenceA4.toStringAsFixed(1)}_${midis.join('_')}';
      final wav = _cache[key] ??= _synthesizePoly(
        midis,
        strumDelayMs: strumDelayMs,
        referenceA4: referenceA4,
      );
      await _player.stop();
      if (token != _sequence) return;
      await _player.play(BytesSource(wav));
    } catch (e, st) {
      debugPrint('GuitarAudioService chord failed: $e\n$st');
    }
  }

  /// [d] kadar bekler; bu sırada yeni bir dizi başladıysa false döner.
  Future<bool> _wait(int token, Duration d) async {
    await Future<void>.delayed(d);
    return token == _sequence;
  }

  Future<void> _ring(int token, Duration d) async {
    await _wait(token, d);
  }

  Future<void> _noRing(int token, Duration d) async {}

  static Uint8List _synthesize(int midi, {double referenceA4 = 440.0}) {
    final freq = referenceA4 * math.pow(2.0, (midi - 69) / 12.0);
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

  static Uint8List _synthesizePoly(
    List<int> midis, {
    double strumDelayMs = 28.0,
    double durationSec = 2.4,
    double referenceA4 = 440.0,
  }) {
    const sampleRate = WavPcm.sampleRate;
    final delaySamples = (sampleRate * (strumDelayMs / 1000.0)).round();
    // Arpejde son nota da tam çınlayabilsin diye süreyi uzat.
    final extra = delaySamples * (midis.length - 1) / sampleRate;
    final totalSamples = (sampleRate * (durationSec + extra)).toInt();
    final out = Float64List(totalSamples);

    for (var s = 0; s < midis.length; s++) {
      final midi = midis[s];
      final freq = referenceA4 * math.pow(2.0, (midi - 69) / 12.0);
      final period = (sampleRate / freq).round().clamp(4, 4096);
      final startOffset = (s * delaySamples).clamp(0, totalSamples - 1);
      final stringSamples = totalSamples - startOffset;

      final rng = math.Random(midi + s * 137);
      final buf = List<double>.generate(period, (_) => rng.nextDouble() * 2 - 1);
      const damping = 0.4984;

      for (var i = 0; i < stringSamples; i++) {
        final idx = i % period;
        final val = buf[idx];
        buf[idx] = (buf[idx] + buf[(idx + 1) % period]) * damping;
        out[startOffset + i] += val;
      }
    }

    var maxVal = 0.0;
    for (var i = 0; i < totalSamples; i++) {
      final abs = out[i].abs();
      if (abs > maxVal) maxVal = abs;
    }
    if (maxVal > 0.85) {
      final scale = 0.85 / maxVal;
      for (var i = 0; i < totalSamples; i++) {
        out[i] *= scale;
      }
    }

    const fadeIn = 64;
    for (var i = 0; i < fadeIn && i < totalSamples; i++) {
      out[i] *= i / fadeIn;
    }

    return WavPcm.mono16Wav(out);
  }
}
