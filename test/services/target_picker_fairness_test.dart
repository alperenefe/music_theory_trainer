import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/target_picker.dart';

void main() {
  test('tur tamamlanmadan hiç çıkmamış nota öncelikli', () {
    final pool = NotationPitch.poolForMidiRange(60, 67);
    final seenMidi = pool.first.midi;
    final hist = List<PracticeAttempt>.generate(
      pool.length - 1,
      (i) => PracticeAttempt(
        exercise: 'yerlestir',
        midi: seenMidi,
        correct: true,
        latencyMs: 300,
        atMillis: i,
      ),
    );
    final neverMidi = pool.last.midi;
    expect(neverMidi, isNot(seenMidi));

    final counts = <int, int>{};
    final rnd = Random(42);
    for (var i = 0; i < 80; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    expect((counts[neverMidi] ?? 0), greaterThan(counts[seenMidi] ?? 0));
  });

  test('sık görülen nota son tur penceresinde geri planda kalır', () {
    final pool = NotationPitch.poolForMidiRange(60, 72);
    final tourLen = pool.length;
    final overMidi = pool.first.midi;
    final hist = <PracticeAttempt>[
      for (var i = 0; i < tourLen; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 300,
          atMillis: i,
        ),
      for (var i = 0; i < tourLen - 1; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: overMidi,
          correct: true,
          latencyMs: 300,
          atMillis: 100 + i,
        ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: pool.last.midi,
        correct: true,
        latencyMs: 300,
        atMillis: 200,
      ),
    ];
    final counts = <int, int>{};
    final rnd = Random(99);
    for (var i = 0; i < 120; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    final overCount = counts[overMidi] ?? 0;
    final rareMidis = pool.map((e) => e.midi).where((m) => m != overMidi);
    var rareTotal = 0;
    for (final m in rareMidis) {
      rareTotal += counts[m] ?? 0;
    }
    expect(overCount, lessThan(rareTotal));
  });

  test('tur tamamlandıktan sonra yanlış yapılan nota daha sık seçilir', () {
    final pool = NotationPitch.poolForMidiRange(60, 67);
    final weakMidi = pool[1].midi;
    final hist = <PracticeAttempt>[
      for (var i = 0; i < pool.length; i++)
        PracticeAttempt(
          exercise: 'coktan_secmeli',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 400,
          atMillis: i,
        ),
      for (var i = 0; i < pool.length * 2; i++)
        PracticeAttempt(
          exercise: 'coktan_secmeli',
          midi: i.isEven ? pool[0].midi : weakMidi,
          correct: i.isEven,
          latencyMs: i.isEven ? 400 : 5200,
          atMillis: 100 + i,
        ),
    ];
    final counts = <int, int>{};
    final rnd = Random(7);
    for (var i = 0; i < 200; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    expect((counts[weakMidi] ?? 0), greaterThan(counts[pool[0].midi] ?? 0));
  });
}
