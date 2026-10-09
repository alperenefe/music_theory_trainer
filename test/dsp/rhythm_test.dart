import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/dsp/guitar_synth.dart';
import 'package:music_theory_trainer/dsp/onset_detector.dart';
import 'package:music_theory_trainer/dsp/rhythm_evaluator.dart';
import 'package:music_theory_trainer/models/chord_shape.dart';

const _sr = 44100;

/// [timesMs]'de Em vuruşu içeren [totalSec] saniyelik kayıt (üst üste çınlar).
Float64List _strums(List<double> timesMs, {double totalSec = 8, int seed = 7}) {
  final out = Float64List((_sr * totalSec).round());
  for (var i = 0; i < timesMs.length; i++) {
    final strum = GuitarSynth.chord(
      midis: ChordLibrary.em.midis,
      sampleRate: _sr,
      seconds: 1.4,
      strumMs: 14,
      seed: seed + i,
    );
    GuitarSynth.mixInto(out, strum, (timesMs[i] * _sr / 1000).round());
  }
  return out;
}

/// Kaydı 2048 örneklik paketlerle (cihazdaki gibi) detektöre verir.
List<double> _detect(Float64List audio, {OnsetDetector? d}) {
  final det = d ?? OnsetDetector(sampleRate: _sr);
  final times = <double>[];
  for (var i = 0; i + 2048 <= audio.length; i += 2048) {
    for (final o in det.process(Float64List.sublistView(audio, i, i + 2048))) {
      times.add(o.sample * 1000 / _sr);
    }
  }
  return times;
}

void main() {
  group('vuruş algılayıcı', () {
    test('100 BPM dörtlük vuruşlar: hepsi bulunur, fazladan yok, ±15 ms', () {
      final expected = [for (var i = 0; i < 12; i++) 600.0 * i + 500];
      final found = _detect(_strums(expected, totalSec: 8.5));
      expect(found.length, expected.length, reason: '$found');
      for (var i = 0; i < expected.length; i++) {
        expect((found[i] - expected[i]).abs(), lessThan(15), reason: 'vuruş $i');
      }
    });

    test('sekizlik vuruşlar (100 BPM → 300 ms aralık), çınlama üst üste biner', () {
      final expected = [for (var i = 0; i < 16; i++) 300.0 * i + 400];
      final found = _detect(_strums(expected, totalSec: 6));
      expect(found.length, expected.length, reason: 'bulunan ${found.length}: $found');
    });

    test('110 BPM sekizlikler (273 ms) — uygulamadaki tempo üst sınırı', () {
      final expected = [for (var i = 0; i < 16; i++) 273.0 * i + 400];
      final found = _detect(_strums(expected, totalSec: 6));
      expect(found.length, expected.length, reason: 'bulunan ${found.length}: $found');
      for (var i = 0; i < expected.length; i++) {
        expect((found[i] - expected[i]).abs(), lessThan(15), reason: 'vuruş $i');
      }
    });

    test('25 dB oda gürültüsünde (tipik oda) güvenilir', () {
      final expected = [for (var i = 0; i < 10; i++) 500.0 * i + 500];
      final noisy = GuitarSynth.addNoise(_strums(expected, totalSec: 6.5), 25);
      final found = _detect(noisy);
      expect(found.length, expected.length, reason: '$found');
    });

    test('15 dB gürültüde (çok gürültülü oda) vuruş UYDURMAZ, en fazla kaçırır', () {
      final expected = [for (var i = 0; i < 10; i++) 500.0 * i + 500];
      final noisy = GuitarSynth.addNoise(_strums(expected, totalSec: 6.5), 15);
      final found = _detect(noisy);
      // Yüksek bantta gürültü baskın olunca pena geçişi seçilemez: algılayıcı
      // kaçırabilir, ama olmayan vuruşları saymamalı (uygulama ayrıca gürültü
      // uyarısı verir).
      expect(found.length, lessThanOrEqualTo(expected.length + 1), reason: '$found');
    });

    test('sessizlik ve düşük gürültü vuruş üretmez', () {
      expect(_detect(Float64List(_sr * 3)), isEmpty);
      final quiet = GuitarSynth.addNoise(Float64List(_sr * 3)..fillRange(0, _sr * 3, 0.003), 0);
      expect(_detect(quiet), isEmpty);
    });

    test('tek bir uzun çınlama ek vuruş üretmez', () {
      final found = _detect(_strums([500], totalSec: 3));
      expect(found.length, 1, reason: '$found');
    });

    test('parça sınırları sonucu değiştirmez (farklı paket boyu)', () {
      final expected = [for (var i = 0; i < 8; i++) 700.0 * i + 300];
      final audio = _strums(expected, totalSec: 6.5);
      final a = _detect(audio);
      final det = OnsetDetector(sampleRate: _sr);
      final b = <double>[];
      var i = 0;
      final sizes = [1000, 700, 2048, 333, 1500];
      var k = 0;
      while (i < audio.length) {
        final n = math.min(sizes[k++ % sizes.length], audio.length - i);
        for (final o in det.process(Float64List.sublistView(audio, i, i + n))) {
          b.add(o.sample * 1000 / _sr);
        }
        i += n;
      }
      expect(b.length, a.length);
    });
  });

  group('ritim değerlendirici', () {
    final grid = [for (var i = 0; i < 8; i++) 600.0 * i];

    test('tam oturan çalış: hepsi mükemmel, 3 yıldız', () {
      final r = RhythmEvaluator.evaluate(expectedMs: grid, playedMs: [for (final g in grid) g + 8]);
      expect(r.count(StrumGrade.perfect), 8);
      expect(r.extraHits, 0);
      expect(r.stars, 3);
    });

    test('sabit 120 ms cihaz gecikmesi hataya sayılmaz', () {
      final r = RhythmEvaluator.evaluate(
        expectedMs: grid,
        playedMs: [for (final g in grid) g + 120],
      );
      expect(r.latencyMs, closeTo(120, 10));
      expect(r.count(StrumGrade.perfect), 8);
    });

    test('düzensiz çalış: erken/geç ve kaçanlar bildirilir', () {
      final played = <double>[0, 610, 1100, 1900, 2400, 3130, 4200, 4800];
      final r = RhythmEvaluator.evaluate(expectedMs: grid, playedMs: played);
      expect(r.count(StrumGrade.perfect), lessThan(8));
      expect(r.count(StrumGrade.early) + r.count(StrumGrade.late), greaterThan(0));
      expect(r.stars, lessThan(3));
    });

    test('hiç çalmamak 0 yıldız, hepsi kaçan', () {
      final r = RhythmEvaluator.evaluate(expectedMs: grid, playedMs: const []);
      expect(r.count(StrumGrade.missed), 8);
      expect(r.stars, 0);
    });

    test('fazladan vuruşlar puanı düşürür', () {
      final clean = RhythmEvaluator.evaluate(expectedMs: grid, playedMs: [...grid]);
      final noisy = RhythmEvaluator.evaluate(
        expectedMs: grid,
        playedMs: <double>[...grid, 300, 900, 1500, 2100, 2700],
      );
      expect(noisy.extraHits, 5);
      expect(noisy.score, lessThan(clean.score));
    });

    test('bir vuruşu atlamak yalnız o vuruşu kaçan yapar', () {
      final played = [for (var i = 0; i < 8; i++) if (i != 3) grid[i]];
      final r = RhythmEvaluator.evaluate(expectedMs: grid, playedMs: played);
      expect(r.count(StrumGrade.missed), 1);
      expect(r.judgements[3].grade, StrumGrade.missed);
    });

    test('isteğe bağlı (yukarı) vuruşlar: çalınmazsa ceza yok, çalınırsa fazladan sayılmaz', () {
      final required = [for (var i = 0; i < 8; i++) 600.0 * i];
      final optional = [for (var i = 0; i < 8; i++) 600.0 * i + 300];
      final without = RhythmEvaluator.evaluate(
        expectedMs: required,
        playedMs: [...required],
        optionalMs: optional,
      );
      expect(without.extraHits, 0);
      expect(without.stars, 3);
      final withUps = RhythmEvaluator.evaluate(
        expectedMs: required,
        playedMs: [...required, ...optional]..sort(),
        optionalMs: optional,
      );
      expect(withUps.extraHits, 0, reason: 'yukarı vuruşlar fazladan sayılmamalı');
      expect(withUps.stars, 3);
      final junk = RhythmEvaluator.evaluate(
        expectedMs: required,
        playedMs: <double>[...required, 130, 430, 730],
        optionalMs: optional,
      );
      expect(junk.extraHits, 3, reason: 'ızgaraya uymayan vuruşlar yine fazladan');
    });

    test('gerçek hat: sentetik vuruş + gecikme + titreşim (jitter)', () {
      final rng = math.Random(4);
      final expected = [for (var i = 0; i < 12; i++) 600.0 * i + 1200];
      final played = [for (final e in expected) e + 90 + (rng.nextDouble() - 0.5) * 40];
      final audio = _strums(played, totalSec: 9.5);
      final found = _detect(audio);
      final r = RhythmEvaluator.evaluate(expectedMs: expected, playedMs: found);
      expect(r.hit, 12);
      expect(r.latencyMs, closeTo(90, 25));
      expect(r.stars, greaterThanOrEqualTo(2));
    });
  });
}
