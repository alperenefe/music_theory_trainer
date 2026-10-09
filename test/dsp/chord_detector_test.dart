import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/dsp/chord_detector.dart';
import 'package:music_theory_trainer/dsp/guitar_synth.dart';
import 'package:music_theory_trainer/models/chord_shape.dart';

const _sr = 44100;

/// Vuruştan ~150 ms sonra başlayan [len] örneklik pencere (uygulamadaki analiz
/// penceresi: pena gürültüsü geçtikten sonraki oturmuş ses).
Float64List _window(Float64List s, {int len = 16384, int from = 6615}) =>
    Float64List.sublistView(s, from, from + len);

Float64List _play(
  ChordShape c, {
  double cents = 0,
  bool karplus = false,
  int seed = 7,
  List<int>? midis,
}) =>
    GuitarSynth.chord(
      midis: midis ?? c.midis,
      sampleRate: _sr,
      seconds: 1.2,
      centsOffset: cents,
      karplus: karplus,
      seed: seed,
    );

void main() {
  final det = ChordDetector(sampleRate: _sr);

  group('hedef akoru tanıma', () {
    for (final c in ChordLibrary.all) {
      test('${c.symbol}: kendi sesini hedef olarak kabul eder', () {
        final spec = det.analyze(_window(_play(c)));
        final r = det.check(c, spec);
        expect(r.isMatch, isTrue, reason: 'skor ${r.score}, en iyi ${r.best?.symbol} ${r.bestScore}');
        expect(r.missingStrings, isEmpty, reason: '${c.symbol} eksik tel');
        expect(r.extraStrings, isEmpty, reason: '${c.symbol} fazla tel');
      });
    }
  });

  group('yanlış akoru reddetme (karışıklık matrisi)', () {
    test('hiçbir akor, başka bir akorun sesini hedef olarak kabul etmez', () {
      final confusions = <String>[];
      for (final played in ChordLibrary.all) {
        final spec = det.analyze(_window(_play(played)));
        for (final target in ChordLibrary.all) {
          if (target.id == played.id) continue;
          final r = det.check(target, spec);
          if (r.isMatch) {
            confusions.add('${played.symbol} çalındı → ${target.symbol} kabul (skor ${r.score.toStringAsFixed(2)}, en iyi ${r.best?.symbol})');
          }
        }
      }
      expect(confusions, isEmpty, reason: confusions.join('\n'));
    });

    test('identify: her akoru doğru adaylar arasından bulur', () {
      for (final c in ChordLibrary.all) {
        final spec = det.analyze(_window(_play(c)));
        expect(det.identify(spec, ChordLibrary.all)?.id, c.id, reason: c.symbol);
      }
    });
  });

  group('gerçekçi bozulmalar', () {
    // Başlangıç yolundaki akorlar: bunların her koşulda doğru bulunması şart.
    final core = [
      ChordLibrary.em, ChordLibrary.am, ChordLibrary.d, ChordLibrary.a,
      ChordLibrary.e, ChordLibrary.c, ChordLibrary.g, ChordLibrary.dm,
    ];

    void expectAll(String name, Float64List Function(ChordShape) make, {ChordDetector? d}) {
      test(name, () {
        final detector = d ?? det;
        final bad = <String>[];
        for (final c in core) {
          final spec = detector.analyze(_window(make(c)));
          final r = detector.check(c, spec, candidates: core);
          if (!r.isMatch) bad.add('${c.symbol}: skor ${r.score.toStringAsFixed(2)}, en iyi ${r.best?.symbol}');
        }
        expect(bad, isEmpty, reason: bad.join('\n'));
      });
    }

    expectAll('gitar 25 cent pes akortlu', (c) => _play(c, cents: -25));
    expectAll('gitar 25 cent tiz akortlu', (c) => _play(c, cents: 25));
    expectAll('15 dB oda gürültüsü', (c) => GuitarSynth.addNoise(_play(c), 15));
    expectAll('10 dB oda gürültüsü', (c) => GuitarSynth.addNoise(_play(c), 10));
    expectAll('uygulamanın kendi Karplus-Strong sesi', (c) => _play(c, karplus: true));
    expectAll('hızlı vuruş (6 ms) ve farklı rastgelelik', (c) {
      return GuitarSynth.chord(midis: c.midis, sampleRate: _sr, strumMs: 6, seed: 99);
    });
    expectAll('yavaş vuruş (45 ms)', (c) {
      return GuitarSynth.chord(midis: c.midis, sampleRate: _sr, strumMs: 45, seed: 5);
    });

    test('akortsuz + gürültü birlikte (kötü ama olası senaryo)', () {
      final bad = <String>[];
      for (final c in core) {
        final s = GuitarSynth.addNoise(_play(c, cents: 18), 12);
        final r = det.check(c, det.analyze(_window(s)), candidates: core);
        if (!r.isMatch) bad.add('${c.symbol}: ${r.score.toStringAsFixed(2)} (${r.best?.symbol})');
      }
      expect(bad, isEmpty, reason: bad.join('\n'));
    });
  });

  group('tel bazlı geri bildirim', () {
    test('Em: B teli (5. tel 2. perde) çalınmazsa eksik tel olarak bildirilir', () {
      final em = ChordLibrary.em;
      // 0: E2, 1: B2 (eksik), 2: E3, 3: G3, 4: B3, 5: E4
      final midis = [40, 52, 55, 59, 64];
      final spec = det.analyze(_window(_play(em, midis: midis)));
      final r = det.check(em, spec);
      expect(r.missingStrings, contains(1), reason: '${r.missingStrings}');
    });

    test('D: susturulması gereken 6. tel de çalınırsa fazla tel bildirilir', () {
      final d = ChordLibrary.d;
      final midis = [40, ...d.midis]; // + açık 6. tel
      final spec = det.analyze(_window(_play(d, midis: midis)));
      final r = det.check(d, spec);
      expect(r.extraStrings, contains(0), reason: '${r.extraStrings} skor ${r.score}');
    });

    test('doğru çalınan akorda yanlış alarm yok', () {
      for (final c in [ChordLibrary.d, ChordLibrary.a, ChordLibrary.am, ChordLibrary.c]) {
        final r = det.check(c, det.analyze(_window(_play(c))));
        expect(r.extraStrings, isEmpty, reason: c.symbol);
        expect(r.missingStrings, isEmpty, reason: c.symbol);
      }
    });
  });

  group('akor olmayan sesler', () {
    test('sessizlik ve gürültü hiçbir akoru kabul etmez', () {
      final silence = det.analyze(Float64List(16384));
      expect(silence.isEmpty, isTrue);
      final noise = GuitarSynth.addNoise(Float64List(16384)..fillRange(0, 16384, 0.001), 0);
      for (final c in ChordLibrary.all) {
        expect(det.check(c, det.analyze(noise)).isMatch, isFalse, reason: c.symbol);
      }
    });

    test('tek tel çalmak akor sayılmaz', () {
      final single = _play(ChordLibrary.em, midis: [45]);
      final spec = det.analyze(_window(single));
      for (final c in [ChordLibrary.em, ChordLibrary.am, ChordLibrary.a]) {
        expect(det.check(c, spec).isMatch, isFalse, reason: c.symbol);
      }
    });
  });
}
