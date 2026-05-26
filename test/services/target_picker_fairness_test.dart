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
      PracticeAttempt(
        exercise: 'coktan_secmeli',
        midi: pool.last.midi,
        correct: true,
        latencyMs: 400,
        atMillis: 300,
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

  test('yavaşlık sabit 4 sn değil; doğru cevap medyanına göre göreli', () {
    final pool = NotationPitch.poolForMidiRange(60, 65);
    final slowMidi = pool[2].midi;
    final fastMidi = pool[0].midi;
    final hist = <PracticeAttempt>[
      for (var i = 0; i < pool.length; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 500,
          atMillis: i,
        ),
      for (var i = 0; i < 24; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: fastMidi,
          correct: true,
          latencyMs: 500,
          atMillis: 50 + i,
        ),
      for (var i = 0; i < 3; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: slowMidi,
          correct: true,
          latencyMs: 2400,
          atMillis: 200 + i,
        ),
      for (var i = 0; i < 3; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: fastMidi,
          correct: true,
          latencyMs: 500,
          atMillis: 300 + i,
        ),
    ];
    final counts = <int, int>{};
    final rnd = Random(11);
    for (var i = 0; i < 200; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    expect((counts[slowMidi] ?? 0), greaterThan(counts[fastMidi] ?? 0));
  });

  test('dar süre dağılımı (3.1–3.5 sn) tek notayı yavaş saymaz', () {
    final pool = NotationPitch.poolForMidiRange(60, 65);
    final hist = <PracticeAttempt>[
      for (var i = 0; i < pool.length; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 3100 + (i % 5) * 100,
          atMillis: i,
        ),
      for (var r = 0; r < 8; r++)
        for (var i = 0; i < pool.length; i++)
          PracticeAttempt(
            exercise: 'yerlestir',
            midi: pool[i].midi,
            correct: true,
            latencyMs: 3100 + (i % 5) * 100,
            atMillis: 50 + r * pool.length + i,
          ),
    ];
    final counts = <int, int>{};
    final rnd = Random(13);
    for (var i = 0; i < 240; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    final values = counts.values.toList()..sort();
    final min = values.first;
    final max = values.last;
    expect(max, lessThan(min * 2.2));
  });

  test('bir önceki nota arka arkaya tekrar sorulmaz', () {
    final pool = NotationPitch.poolForMidiRange(60, 64);
    final lastMidi = pool.first.midi;
    final hist = <PracticeAttempt>[
      for (var i = 0; i < pool.length; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 400,
          atMillis: i,
        ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: lastMidi,
        correct: false,
        latencyMs: 2000,
        atMillis: 99,
      ),
    ];
    final rnd = Random(3);
    for (var i = 0; i < 60; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      expect(p.midi, isNot(lastMidi));
    }
  });

  test('çok yanlış nota çok doğru olandan belirgin sık seçilir', () {
    final pool = NotationPitch.poolForMidiRange(60, 67);
    final badMidi = pool[0].midi;
    final goodMidi = pool[pool.length - 1].midi;
    final hist = <PracticeAttempt>[
      for (var i = 0; i < pool.length; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 500,
          atMillis: i,
        ),
      for (var i = 0; i < 20; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: goodMidi,
          correct: true,
          latencyMs: 500,
          atMillis: 50 + i,
        ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: badMidi,
        correct: false,
        latencyMs: 3000,
        atMillis: 200,
      ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: badMidi,
        correct: false,
        latencyMs: 2800,
        atMillis: 201,
      ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: goodMidi,
        correct: true,
        latencyMs: 520,
        atMillis: 202,
      ),
    ];
    final counts = <int, int>{};
    final rnd = Random(21);
    for (var i = 0; i < 300; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    final bad = counts[badMidi] ?? 0;
    final good = counts[goodMidi] ?? 0;
    expect(bad, greaterThan(good * 1.35));
  });

  test('son 2 yanlış nota, son 2 doğru olandan en az 2 kat sık', () {
    final pool = NotationPitch.poolForMidiRange(60, 67);
    final weakMidi = pool.first.midi;
    final strongMidi = pool.last.midi;
    final hist = <PracticeAttempt>[
      for (var i = 0; i < pool.length; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 500,
          atMillis: i,
        ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: weakMidi,
        correct: false,
        latencyMs: 800,
        atMillis: 100,
      ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: weakMidi,
        correct: false,
        latencyMs: 900,
        atMillis: 101,
      ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: strongMidi,
        correct: true,
        latencyMs: 500,
        atMillis: 102,
      ),
      PracticeAttempt(
        exercise: 'yerlestir',
        midi: strongMidi,
        correct: true,
        latencyMs: 520,
        atMillis: 103,
      ),
    ];
    final counts = <int, int>{};
    final rnd = Random(31);
    for (var i = 0; i < 400; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    expect(counts[weakMidi] ?? 0, greaterThan((counts[strongMidi] ?? 0) * 2));
  });

  test('aynı birimdeki iyi notalar yaklaşık eşit seçilir', () {
    final pool = NotationPitch.poolForMidiRange(60, 67);
    final hist = <PracticeAttempt>[
      for (var i = 0; i < pool.length; i++)
        PracticeAttempt(
          exercise: 'yerlestir',
          midi: pool[i].midi,
          correct: true,
          latencyMs: 500,
          atMillis: i,
        ),
      for (final m in pool.map((e) => e.midi))
        ...[
          PracticeAttempt(
            exercise: 'yerlestir',
            midi: m,
            correct: true,
            latencyMs: 500,
            atMillis: 200,
          ),
          PracticeAttempt(
            exercise: 'yerlestir',
            midi: m,
            correct: true,
            latencyMs: 520,
            atMillis: 201,
          ),
        ],
    ];
    final counts = <int, int>{};
    final rnd = Random(17);
    for (var i = 0; i < 500; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    final values = counts.values.toList()..sort();
    expect(values.last, lessThan(values.first * 2.2));
  });
}
