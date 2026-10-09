import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/dsp/guitar_synth.dart';
import 'package:music_theory_trainer/dsp/strum_session.dart';
import 'package:music_theory_trainer/models/chord_shape.dart';
import 'package:music_theory_trainer/models/strum_pattern.dart';
import 'package:music_theory_trainer/services/chord_listener.dart';
import 'package:music_theory_trainer/services/open_string_listener.dart';
import 'package:music_theory_trainer/services/progression_judge.dart';

const _sr = 44100;

List<Float64List> _chunks(Float64List a, {int size = 2048}) => [
      for (var i = 0; i + size <= a.length; i += size) Float64List.sublistView(a, i, i + size),
    ];

Float64List _silence(double seconds) => Float64List((seconds * _sr).round());

void main() {
  group('ChordListener', () {
    test('doğru akor birkaç analizde onaylanır', () {
      final l = ChordListener(sampleRate: _sr, target: ChordLibrary.g);
      final sig = GuitarSynth.addNoise(
        GuitarSynth.chord(midis: ChordLibrary.g.midis, sampleRate: _sr, seconds: 1.5, strumMs: 18),
        30,
        seed: 3,
      );
      for (final c in _chunks(sig)) {
        l.feed(c);
      }
      expect(l.confirmed, isTrue, reason: 'streak ${l.streak}');
    });

    test('yanlış akor onaylanmaz', () {
      final l = ChordListener(sampleRate: _sr, target: ChordLibrary.g);
      final sig = GuitarSynth.chord(
          midis: ChordLibrary.c.midis, sampleRate: _sr, seconds: 1.5, strumMs: 18);
      for (final c in _chunks(sig)) {
        l.feed(c);
      }
      expect(l.confirmed, isFalse);
    });

    test('sessizlikte onay yok', () {
      final l = ChordListener(sampleRate: _sr, target: ChordLibrary.em);
      for (final c in _chunks(_silence(1.5))) {
        l.feed(c);
      }
      expect(l.confirmed, isFalse);
    });
  });

  group('OpenStringListener', () {
    for (var s = 0; s < 6; s++) {
      test('${s + 1}. sıra tel doğru bulunur', () {
        final l = OpenStringListener(sampleRate: _sr);
        final sig = GuitarSynth.string(
          hz: GuitarSynth.hzFromMidi(ChordShape.openStringMidi[s]),
          sampleRate: _sr,
          seconds: 1.4,
          seed: s,
        );
        final heard = <StringHeard>[];
        for (final c in _chunks(sig)) {
          final h = l.feed(c);
          if (h != null) heard.add(h);
        }
        expect(heard, isNotEmpty);
        expect(heard.first.string, s);
        expect(heard.first.cents.abs(), lessThan(15));
        expect(heard.length, 1, reason: 'aynı tel tekrar bildirilmemeli');
      });
    }

    test('20 sent akortsuz tel, sapmasıyla bildirilir', () {
      final l = OpenStringListener(sampleRate: _sr);
      final sig = GuitarSynth.string(
        hz: GuitarSynth.hzFromMidi(50) * math.pow(2, 20 / 1200),
        sampleRate: _sr,
        seconds: 1.4,
      );
      StringHeard? h;
      for (final c in _chunks(sig)) {
        h ??= l.feed(c);
      }
      expect(h?.string, 2);
      expect(h!.cents, closeTo(20, 8));
    });

    test('sessizlik ve gürültü tel sayılmaz', () {
      final l = OpenStringListener(sampleRate: _sr);
      final noise = GuitarSynth.addNoise(_silence(1.5), 20, seed: 4);
      for (final c in _chunks(noise)) {
        expect(l.feed(c), isNull);
      }
    });
  });

  group('ProgressionJudge', () {
    final session = StrumSession(pattern: StrumPatterns.quarters, bpm: 70, bars: 4);
    final loop = [ChordLibrary.g, ChordLibrary.d, ChordLibrary.em, ChordLibrary.c];

    Float64List play(List<ChordShape> perBar, {double latencyMs = 100}) {
      final out = Float64List((_sr * (session.totalMs / 1000 + 1.5)).round());
      for (var b = 0; b < session.bars; b++) {
        for (var beat = 0; beat < 4; beat++) {
          final t = session.playStartMs + b * session.barMs + beat * session.beatMs + latencyMs;
          GuitarSynth.mixInto(
            out,
            GuitarSynth.chord(
                midis: perBar[b].midis,
                sampleRate: _sr,
                seconds: 0.8,
                strumMs: 14,
                seed: b * 4 + beat),
            (t * _sr / 1000).round(),
          );
        }
      }
      return GuitarSynth.addNoise(out, 30, seed: 8);
    }

    test('hepsi doğru çalınırsa 4/4 ölçü eşleşir', () {
      final r = ProgressionJudge.judge(
        audio: play(loop),
        sampleRate: _sr,
        session: session,
        barChords: loop,
        latencyMs: 100,
      );
      expect(r.matched, 4, reason: r.perBar.map((a) => a?.best?.id).toString());
    });

    test('bir ölçüde yanlış akor çalınırsa o ölçü sayılmaz', () {
      final r = ProgressionJudge.judge(
        audio: play([ChordLibrary.g, ChordLibrary.d, ChordLibrary.c, ChordLibrary.c]),
        sampleRate: _sr,
        session: session,
        barChords: loop,
        latencyMs: 100,
      );
      expect(r.perBar[2]?.isMatch, isFalse);
      expect(r.matched, 3);
    });

    test('hep aynı akoru çalmak döngüyü geçirmez', () {
      final r = ProgressionJudge.judge(
        audio: play(List.filled(4, ChordLibrary.g)),
        sampleRate: _sr,
        session: session,
        barChords: loop,
        latencyMs: 100,
      );
      expect(r.matched, lessThanOrEqualTo(1));
    });

    test('yıldız: yanlış akorlarla ritim mükemmel olsa da yüksek yıldız yok', () {
      expect(ProgressionJudge.stars(rhythmScore: 1, chordFraction: 0.25), lessThanOrEqualTo(0));
      expect(ProgressionJudge.stars(rhythmScore: 0.9, chordFraction: 1), 3);
      expect(ProgressionJudge.stars(rhythmScore: 0.6, chordFraction: 0.75), 2);
    });
  });
}
