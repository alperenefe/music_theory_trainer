import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/dsp/chord_change_counter.dart';
import 'package:music_theory_trainer/dsp/guitar_synth.dart';
import 'package:music_theory_trainer/models/chord_shape.dart';

const _sr = 44100;

/// [plays]: (başlangıç ms, akor, midis?) — her çalış ayrı bir vuruş.
///
/// Akor değişirken parmaklar kalkıp yeni şekil basıldığı için bir önceki akor
/// bir sonraki vuruşta boğulur (yaklaşık 40 ms'de söner). Boğmadan üst üste
/// bindirmek gerçekçi olmaz: eski akor yeni vuruşun altında sonsuza dek çınlardı.
Float64List _session(List<(double, ChordShape, List<int>?)> plays, {double totalSec = 20, int seed = 3}) {
  final out = Float64List((_sr * totalSec).round());
  for (var i = 0; i < plays.length; i++) {
    final (t, c, midis) = plays[i];
    final strum = GuitarSynth.chord(
      midis: midis ?? c.midis,
      sampleRate: _sr,
      seconds: 1.3,
      strumMs: 14,
      seed: seed + i * 5,
    );
    if (i + 1 < plays.length) {
      final keep = ((plays[i + 1].$1 - t) * _sr / 1000).round() + (0.02 * _sr).round();
      final fade = (0.04 * _sr).round();
      for (var k = 0; k < strum.length; k++) {
        if (k > keep + fade) {
          strum[k] = 0;
        } else if (k > keep) {
          strum[k] *= 1 - (k - keep) / fade;
        }
      }
    }
    GuitarSynth.mixInto(out, strum, (t * _sr / 1000).round());
  }
  return out;
}

ChordChangeCounter _run(ChordShape a, ChordShape b, Float64List audio) {
  final c = ChordChangeCounter(sampleRate: _sr, a: a, b: b);
  for (var i = 0; i + 2048 <= audio.length; i += 2048) {
    c.process(Float64List.sublistView(audio, i, i + 2048));
  }
  c.flush();
  return c;
}

void main() {
  group('akor değişimi sayacı', () {
    test('A↔D: 12 vuruş, 11 değişim (ilk akor değişim sayılmaz)', () {
      final a = ChordLibrary.a, d = ChordLibrary.d;
      final plays = [
        for (var i = 0; i < 12; i++) (800.0 + i * 1000, i.isEven ? a : d, null),
      ];
      final c = _run(a, d, _session(plays, totalSec: 15));
      expect(c.changes, 11, reason: 'vuruş ${c.strums}, tanınmayan ${c.unrecognized}');
      expect(c.strums, 12);
      expect(c.unrecognized, 0);
    });

    test('aynı akoru art arda çalmak değişim sayılmaz', () {
      final em = ChordLibrary.em, am = ChordLibrary.am;
      final plays = [
        (800.0, em, null),
        (1800.0, em, null),
        (2800.0, em, null),
        (3800.0, am, null),
        (4800.0, am, null),
        (5800.0, em, null),
      ];
      final c = _run(em, am, _session(plays, totalSec: 8));
      expect(c.changes, 2, reason: 'em→am, am→em');
    });

    test('hızlı geçiş: saniyede 1.5 değişim (dakikada 90)', () {
      final g = ChordLibrary.g, c0 = ChordLibrary.c;
      final plays = [
        for (var i = 0; i < 14; i++) (600.0 + i * 650, i.isEven ? g : c0, null),
      ];
      final c = _run(g, c0, _session(plays, totalSec: 11));
      expect(c.changes, 13, reason: 'vuruş ${c.strums}');
    });

    test('yanlış akor çalmak değişim sayılmaz, tanınmayan olarak kaydedilir', () {
      final d = ChordLibrary.d, a = ChordLibrary.a;
      final plays = [
        (800.0, d, null),
        (1800.0, a, null),
        // A yerine Em çalındı: ne A ne D; sayılmamalı.
        (2800.0, ChordLibrary.em, null),
        (3800.0, d, null),
      ];
      final c = _run(d, a, _session(plays, totalSec: 6));
      expect(c.changes, 2, reason: 'd→a ve a→d; Em sayılmaz');
      expect(c.unrecognized, 1);
    });

    test('tek tel çalmak (akor değil) hiçbir şeyi bozmaz', () {
      final d = ChordLibrary.d, a = ChordLibrary.a;
      final plays = [
        (800.0, d, null),
        (1800.0, a, null),
        (2800.0, a, [45]),
        (3800.0, d, null),
      ];
      final c = _run(d, a, _session(plays, totalSec: 6));
      expect(c.changes, 2);
    });

    test('25 dB oda gürültüsünde de doğru sayar', () {
      final em = ChordLibrary.em, a = ChordLibrary.a;
      final plays = [
        for (var i = 0; i < 10; i++) (800.0 + i * 1000, i.isEven ? em : a, null),
      ];
      final audio = GuitarSynth.addNoise(_session(plays, totalSec: 12), 25);
      final c = _run(em, a, audio);
      expect(c.changes, 9, reason: 'vuruş ${c.strums}, tanınmayan ${c.unrecognized}');
    });

    test('çalmadan beklemek hiçbir şey saymaz', () {
      final c = _run(ChordLibrary.em, ChordLibrary.am, Float64List(_sr * 5));
      expect(c.changes, 0);
      expect(c.strums, 0);
    });

    test('rastgele sırayla 40 değişim: hata payı en fazla 1', () {
      final rng = math.Random(11);
      final a = ChordLibrary.a, d = ChordLibrary.d;
      var cur = a;
      var expectedChanges = 0;
      final plays = <(double, ChordShape, List<int>?)>[];
      for (var i = 0; i < 41; i++) {
        final switchChord = i > 0 && rng.nextBool();
        if (switchChord) {
          cur = cur.id == a.id ? d : a;
          expectedChanges++;
        }
        plays.add((700.0 + i * 1100, cur, null));
      }
      final c = _run(a, d, _session(plays, totalSec: 49));
      expect((c.changes - expectedChanges).abs(), lessThanOrEqualTo(1),
          reason: 'beklenen $expectedChanges, sayılan ${c.changes}');
    });
  });
}
