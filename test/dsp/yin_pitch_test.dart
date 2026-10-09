import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/dsp/guitar_synth.dart';
import 'package:music_theory_trainer/dsp/yin_pitch.dart';

double _cents(double a, double b) => 1200 * math.log(a / b) / math.ln2;

/// Çalan notanın hemen başından 2048 örneklik pencere (cihazdaki paket boyu).
Float64List _frame(Float64List s, {int from = 600, int len = 2048}) =>
    Float64List.sublistView(s, from, from + len);

void main() {
  const sr = 44100;
  final yin = YinPitchDetector(sampleRate: sr);

  group('YIN: açık teller', () {
    // Standart akort: E2 A2 D3 G3 B3 E4.
    const open = [40, 45, 50, 55, 59, 64];
    for (final midi in open) {
      test('midi $midi 2048 örneklik pencerede ±5 cent', () {
        final hz = GuitarSynth.hzFromMidi(midi);
        final s = GuitarSynth.string(hz: hz, sampleRate: sr, seconds: 0.5);
        final est = yin.detect(_frame(s));
        expect(est, isNotNull);
        expect(_cents(est!.hz, hz).abs(), lessThan(5), reason: 'hz=${est.hz}');
        expect(est.clarity, greaterThan(0.8));
      });
    }
  });

  group('YIN: dayanıklılık', () {
    test('perdelenmiş her nota E2..E5 aralığında doğru oktavı bulur', () {
      for (var midi = 40; midi <= 76; midi++) {
        final hz = GuitarSynth.hzFromMidi(midi);
        final s = GuitarSynth.string(hz: hz, sampleRate: sr, seconds: 0.5);
        final est = yin.detect(_frame(s));
        expect(est, isNotNull, reason: 'midi $midi');
        expect(_cents(est!.hz, hz).abs(), lessThan(8), reason: 'midi $midi → ${est.hz}');
      }
    });

    test('15 dB gürültüde hâlâ ±15 cent', () {
      for (final midi in [40, 45, 52, 59, 64, 69]) {
        final hz = GuitarSynth.hzFromMidi(midi);
        final clean = GuitarSynth.string(hz: hz, sampleRate: sr, seconds: 0.5);
        final noisy = GuitarSynth.addNoise(clean, 15);
        final est = yin.detect(_frame(noisy));
        expect(est, isNotNull, reason: 'midi $midi');
        expect(_cents(est!.hz, hz).abs(), lessThan(15), reason: 'midi $midi');
      }
    });

    test('akortsuz tel (-30 cent) olduğu gibi raporlanır (akort cihazı için)', () {
      final target = GuitarSynth.hzFromMidi(45);
      final flat = GuitarSynth.hzFromMidi(45 - 0.30);
      final s = GuitarSynth.string(hz: flat, sampleRate: sr, seconds: 0.5);
      final est = yin.detect(_frame(s))!;
      expect(_cents(est.hz, target), closeTo(-30, 6));
    });

    test('pes tel, harmonikleri güçlü olsa bile temel frekansı verir', () {
      // 2. harmoniği temelden güçlü bir E2: sıfır geçiş yöntemi bunu oktav
      // yukarı okurdu.
      final f0 = GuitarSynth.hzFromMidi(40);
      final out = Float64List(sr ~/ 2);
      for (var i = 0; i < out.length; i++) {
        final t = i / sr;
        out[i] = 0.35 * math.sin(2 * math.pi * f0 * t) +
            0.8 * math.sin(2 * math.pi * 2 * f0 * t) +
            0.6 * math.sin(2 * math.pi * 3 * f0 * t) +
            0.4 * math.sin(2 * math.pi * 4 * f0 * t);
      }
      final est = yin.detect(_frame(out))!;
      expect(_cents(est.hz, f0).abs(), lessThan(8));
    });

    test('sessizlik ve saf gürültü perde üretmez', () {
      expect(yin.detect(Float64List(2048)), isNull);
      final rng = math.Random(5);
      final noise = Float64List.fromList(
        List.generate(2048, (_) => rng.nextDouble() * 2 - 1),
      );
      expect(yin.detect(noise), isNull);
    });

    test('Karplus-Strong (uygulamanın kendi sentezi) için de çalışır', () {
      for (final midi in [40, 45, 50, 55, 59, 64]) {
        final hz = GuitarSynth.hzFromMidi(midi);
        final s = GuitarSynth.karplusStrong(hz: hz, sampleRate: sr, seconds: 0.5);
        final est = yin.detect(_frame(s, from: 200));
        expect(est, isNotNull, reason: 'midi $midi');
        // KS kendi döngü gecikmesi nedeniyle bir miktar pes çıkar.
        expect(_cents(est!.hz, hz).abs(), lessThan(25), reason: 'midi $midi');
      }
    });
  });

  group('Eski yöntem karşılaştırması', () {
    int zeroCrossHz(Float64List f, int sr) {
      var c = 0;
      for (var i = 1; i < f.length; i++) {
        if ((f[i - 1] > 0 && f[i] <= 0) || (f[i - 1] < 0 && f[i] >= 0)) c++;
      }
      return ((c / 2) / (f.length / sr)).round();
    }

    test('sıfır geçiş yöntemi (eski) pes telleri yanlış okur, YIN okumaz', () {
      var zcWrong = 0;
      var yinWrong = 0;
      for (final midi in [40, 45, 50, 55]) {
        final hz = GuitarSynth.hzFromMidi(midi);
        final s = GuitarSynth.string(hz: hz, sampleRate: sr, seconds: 0.5);
        final f = _frame(s);
        if (_cents(zeroCrossHz(f, sr).toDouble(), hz).abs() > 50) zcWrong++;
        final e = yin.detect(f);
        if (e == null || _cents(e.hz, hz).abs() > 50) yinWrong++;
      }
      expect(yinWrong, 0);
      // Eski yöntemin gerçekten sorunlu olduğunu belgeleyen bir ölçüm.
      expect(zcWrong, greaterThan(0));
    });
  });
}
