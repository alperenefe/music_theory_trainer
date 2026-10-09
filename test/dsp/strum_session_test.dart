import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/dsp/guitar_synth.dart';
import 'package:music_theory_trainer/dsp/metronome_track.dart';
import 'package:music_theory_trainer/dsp/onset_detector.dart';
import 'package:music_theory_trainer/dsp/strum_session.dart';
import 'package:music_theory_trainer/models/chord_shape.dart';
import 'package:music_theory_trainer/models/strum_pattern.dart';

const _sr = 44100;

/// Metronom WAV'ını (22050 Hz) mikrofon hızına (44100 Hz) çevirip float'a açar.
Float64List _clicksFromTrack(MetronomeTrack track) {
  final bd = ByteData.sublistView(track.wav);
  final n = (track.wav.length - 44) ~/ 2;
  final src = Float64List(n);
  for (var i = 0; i < n; i++) {
    src[i] = bd.getInt16(44 + i * 2, Endian.little) / 32768.0;
  }
  final out = Float64List(n * 2);
  for (var i = 0; i < n; i++) {
    final a = src[i];
    final b = i + 1 < n ? src[i + 1] : a;
    out[2 * i] = a;
    out[2 * i + 1] = (a + b) / 2;
  }
  return out;
}

/// Bir egzersizin mikrofon kaydını sentezler.
///
/// [leakGain]: hoparlörden mikrofona giren metronom (0 = kulaklık).
/// [playerLatencyMs]: kullanıcının metronomu geç duyup geç çalması + cihaz gecikmesi.
/// [play]: false ise kullanıcı hiç çalmaz (yalnız sızıntı).
Float64List _recording(
  StrumSession s, {
  double leakGain = 0.0,
  double leakDelayMs = 110,
  double playerLatencyMs = 110,
  double jitterMs = 10,
  bool play = true,
  int seed = 5,
  double noiseDb = 30,
}) {
  final out = Float64List((_sr * (s.totalMs / 1000 + 1.5)).round());
  if (leakGain > 0) {
    final track = MetronomeTrack.generate(bpm: s.bpm, totalBars: s.totalBars);
    final clicks = _clicksFromTrack(track);
    for (var i = 0; i < clicks.length; i++) {
      final j = i + (leakDelayMs * _sr / 1000).round();
      if (j < out.length) out[j] += clicks[i] * leakGain;
    }
  }
  if (play) {
    final rng = math.Random(seed);
    final chord = ChordLibrary.em.midis;
    var k = 0;
    for (final t in s.expectedDownMs) {
      final at = t + playerLatencyMs + (rng.nextDouble() - 0.5) * 2 * jitterMs;
      GuitarSynth.mixInto(
        out,
        GuitarSynth.chord(midis: chord, sampleRate: _sr, seconds: 0.9, strumMs: 14, seed: seed + k++),
        (at * _sr / 1000).round(),
      );
    }
    for (final t in s.expectedUpMs) {
      final at = t + playerLatencyMs + (rng.nextDouble() - 0.5) * 2 * jitterMs;
      // Yukarı vuruş: tizden peste, daha sessiz.
      final up = GuitarSynth.chord(
        midis: chord.reversed.toList(),
        sampleRate: _sr,
        seconds: 0.5,
        strumMs: 10,
        seed: seed + k++,
      );
      for (var i = 0; i < up.length; i++) {
        up[i] *= 0.45;
      }
      GuitarSynth.mixInto(out, up, (at * _sr / 1000).round());
    }
  }
  return noiseDb > 0 ? GuitarSynth.addNoise(out, noiseDb, seed: seed + 100) : out;
}

List<DetectedStrum> _detect(Float64List audio) {
  final det = OnsetDetector(sampleRate: _sr);
  final found = <DetectedStrum>[];
  for (var i = 0; i + 2048 <= audio.length; i += 2048) {
    for (final o in det.process(Float64List.sublistView(audio, i, i + 2048))) {
      found.add(DetectedStrum(o.sample * 1000 / _sr, o.strength));
    }
  }
  return found;
}

StrumSession _session(StrumPattern p, {int bpm = 80, int bars = 4}) =>
    StrumSession(pattern: p, bpm: bpm, bars: bars);

void main() {
  group('zaman çizelgesi', () {
    test('klasik kalıp: ölçü başına 3 aşağı + 2 yukarı vuruş, doğru zamanlarda', () {
      final s = _session(StrumPatterns.classic, bpm: 60, bars: 2);
      expect(s.beatMs, 1000);
      expect(s.playStartMs, 4000);
      // 1. ölçü: slotlar 0, 2, 6 → 0, 1000, 3000 ms
      expect(s.expectedDownMs.take(3).toList(), [4000, 5000, 7000]);
      expect(s.expectedUpMs.take(2).toList(), [5500, 6500]);
      expect(s.expectedDownMs.length, 6);
      expect(s.clickTimesMs.length, 12); // 3 ölçü × 4
    });

    test('metronom parçası: tıklama zamanları tempoya uyar', () {
      final t = MetronomeTrack.generate(bpm: 120, totalBars: 2);
      expect(t.clickTimesMs.length, 8);
      expect(t.clickTimesMs[1] - t.clickTimesMs[0], closeTo(500, 0.1));
      expect(t.totalMs, closeTo(4000, 0.1));
      expect(t.wav.take(4).toList(), [0x52, 0x49, 0x46, 0x46]); // "RIFF"
    });
  });

  group('uçtan uca: gürültülü odada, gecikmeli ve titrek çalış', () {
    for (final p in StrumPatterns.all) {
      test('${p.name} (kulaklık): 2+ yıldız, vuruşlar bulunur', () {
        final s = _session(p, bpm: p.hasUps ? 80 : 90);
        final report = s.evaluate(_detect(_recording(s)));
        final r = report.result;
        expect(r.hit, s.expectedDownMs.length, reason: 'bulunan ${r.hit}/${r.expected}');
        expect(r.stars, greaterThanOrEqualTo(2), reason: 'skor ${r.score}');
        expect(r.latencyMs, closeTo(110, 40));
        expect(report.leakDetected, isFalse);
      });
    }

    test('hoparlör sızıntısı varken de doğru puanlar', () {
      final s = _session(StrumPatterns.classic);
      final report = s.evaluate(_detect(_recording(s, leakGain: 0.3)));
      // Yumuşak, alçak frekanslı tıklama algılayıcıya neredeyse görünmez; sızıntı
      // filtresi yalnızca ikinci bir güvence. Önemli olan sonucun doğru çıkması.
      expect(report.result.hit, s.expectedDownMs.length);
      expect(report.result.stars, greaterThanOrEqualTo(2), reason: 'skor ${report.result.score}');
      expect(report.result.extraHits, lessThanOrEqualTo(2));
    });

    test('KRİTİK: hiç çalmayıp yalnız sızan metronomla puan alınamaz', () {
      for (final p in [StrumPatterns.quarters, StrumPatterns.classic]) {
        final s = _session(p);
        final report = s.evaluate(_detect(_recording(s, leakGain: 0.3, play: false)));
        expect(report.result.stars, 0, reason: '${p.id}: yalnız tıklama puan getirdi');
        expect(report.result.hit, lessThanOrEqualTo(1), reason: '${p.id} hit ${report.result.hit}');
      }
    });

    test('sızıntısız sessiz kayıt (hiç çalmadı) 0 yıldız', () {
      final s = _session(StrumPatterns.quarters);
      final report = s.evaluate(_detect(_recording(s, play: false)));
      expect(report.result.stars, 0);
      expect(report.result.hit, 0);
    });

    test('metronomun tam üstünde çalmak (vuruş = tıklama) sızıntı sanılmaz', () {
      // Kullanıcı tıklamayla aynı anda çalıyor: toplam enerji tıklamadan güçlü.
      final s = _session(StrumPatterns.quarters, bpm: 70);
      final report = s.evaluate(
        _detect(_recording(s, leakGain: 0.25, leakDelayMs: 110, playerLatencyMs: 110, jitterMs: 6)),
      );
      expect(report.result.hit, greaterThanOrEqualTo(s.expectedDownMs.length - 1),
          reason: 'bulunan ${report.result.hit}/${report.result.expected}');
    });

    test('sürekli geç çalan oyuncu: ritim düzenliyse yine iyi puan (gecikme çıkarılır)', () {
      final s = _session(StrumPatterns.quarters, bpm: 80);
      final report = s.evaluate(_detect(_recording(s, playerLatencyMs: 190, jitterMs: 8)));
      expect(report.result.latencyMs, closeTo(190, 40));
      expect(report.result.stars, greaterThanOrEqualTo(2));
    });

    test('bluetooth kulaklık: 320 ms toplam gecikme yine de doğru puanlanır', () {
      final s = _session(StrumPatterns.quarters, bpm: 70);
      final report = s.evaluate(_detect(_recording(s, playerLatencyMs: 320, jitterMs: 8)));
      expect(report.result.latencyMs, closeTo(320, 50));
      expect(report.result.hit, s.expectedDownMs.length);
      expect(report.result.stars, greaterThanOrEqualTo(2));
    });

    test('düzensiz çalan oyuncu düşük puan alır', () {
      final s = _session(StrumPatterns.quarters, bpm: 80);
      final report = s.evaluate(_detect(_recording(s, jitterMs: 130, seed: 9)));
      expect(report.result.stars, lessThanOrEqualTo(2));
      expect(report.result.jitterMs, greaterThan(40));
    });
  });
}
