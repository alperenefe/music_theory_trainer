import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/theory/interval_question.dart';
import 'package:music_theory_trainer/theory/music_interval.dart';
import 'package:music_theory_trainer/theory/theory_note_labels.dart';

void main() {
  test('soru oktav içermez, cevaplar oktavsız', () {
    final q = IntervalQuestion.random(Random(1), 60, 72);
    expect(q.prompt, isNot(contains('oktav')));
    expect(q.correctLabel, isNot(contains('oktav')));
    for (final o in q.options) {
      expect(o, isNot(contains('oktav')));
    }
  });

  test('prompt kök + yön + aralık türü', () {
    final q = IntervalQuestion.random(Random(2), 60, 72);
    expect(q.prompt, contains("'un"));
    expect(
      q.prompt,
      anyOf(contains('yukarı'), contains('aşağı')),
    );
    expect(
      q.prompt,
      anyOf(
        contains('2li'),
        contains('3lü'),
        contains('4lü'),
        contains('5li'),
        contains('6lı'),
        contains('7li'),
        contains('tritonus'),
      ),
    );
    expect(q.prompt, isNot(contains('oktav')));
  });

  test('cevap doğru aralık', () {
    final rnd = Random(3);
    for (var i = 0; i < 20; i++) {
      final q = IntervalQuestion.random(rnd, 55, 75);
      final expected = MusicInterval.apply(q.rootMidi, q.kind, up: q.up);
      expect(q.answerMidi, expected);
      expect(
        q.correctLabel,
        TheoryNoteLabels.label(expected, withOctave: false),
      );
    }
  });

  test('practiceSet oktav içermez', () {
    expect(MusicInterval.practiceSet, isNot(contains(IntervalKind.octave)));
  });
}
