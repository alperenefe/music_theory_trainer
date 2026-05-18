import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/notation_pitch.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/target_picker.dart';

void main() {
  test('kısa geçmişte düzgün dağılım', () {
    final pool = NotationPitch.poolForMidiRange(60, 72);
    final rnd = Random(1);
    final hist = List<PracticeAttempt>.generate(10, (i) {
      return PracticeAttempt(
        exercise: 'coktan_secmeli',
        midi: pool[i % pool.length].midi,
        correct: true,
        latencyMs: 400,
        atMillis: i,
      );
    });
    final counts = <int, int>{};
    for (var i = 0; i < 200; i++) {
      final p = TargetPicker.pick(rnd, pool, hist);
      counts[p.midi] = (counts[p.midi] ?? 0) + 1;
    }
    expect(counts.length, greaterThan(1));
  });

  test('uzun geçmişte havuzdan seçer', () {
    final pool = NotationPitch.trainingPool();
    final rnd = Random(2);
    final hist = List<PracticeAttempt>.generate(80, (i) {
      return PracticeAttempt(
        exercise: 'coktan_secmeli',
        midi: pool[i % pool.length].midi,
        correct: i.isEven,
        latencyMs: i.isEven ? 800 : 5000,
        atMillis: i,
      );
    });
    final p = TargetPicker.pick(rnd, pool, hist);
    expect(pool.any((e) => e.midi == p.midi), isTrue);
  });
}
