import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/ear_curriculum.dart';
import 'package:music_theory_trainer/models/ear_exercise_kind.dart';

void main() {
  test('12 weeks, each with a substantial lesson', () {
    expect(earCurriculumWeeks, hasLength(12));
    for (final w in earCurriculumWeeks) {
      expect(w.lesson.length, greaterThanOrEqualTo(5), reason: 'hafta ${w.weekNumber}');
      for (final p in w.lesson) {
        expect(p.heading.trim(), isNotEmpty);
        expect(p.body.trim(), isNotEmpty);
      }
    }
  });

  test('every week has key ideas, listenable sounds and something to try', () {
    for (final w in earCurriculumWeeks) {
      final keyIdeas = w.lesson.where((p) => p.keyIdea != null).length;
      expect(keyIdeas, greaterThanOrEqualTo(3), reason: 'hafta ${w.weekNumber}');
      expect(w.lesson.any((p) => p.sound != null), isTrue, reason: 'hafta ${w.weekNumber}');
    }
    final tryCount = earCurriculumWeeks
        .expand((w) => w.lesson)
        .where((p) => p.tryThis != null)
        .length;
    expect(tryCount, greaterThanOrEqualTo(15));
  });

  test('A/B comparisons always come with both labels', () {
    for (final p in earCurriculumWeeks.expand((w) => w.lesson)) {
      if (p.compareSound != null) {
        expect(p.sound, isNotNull, reason: p.heading);
        expect(p.soundLabel, isNotNull, reason: p.heading);
        expect(p.compareLabel, isNotNull, reason: p.heading);
      }
    }
  });

  test('glossary grows week by week and terms are defined only once', () {
    final w1 = earGlossaryUpTo(1);
    final w12 = earGlossaryUpTo(12);
    expect(w1, contains('Yarım ses'));
    expect(w12.length, greaterThan(w1.length));
    expect(w12.length, greaterThanOrEqualTo(40));

    final seen = <String>{};
    for (final p in earCurriculumWeeks.expand((w) => w.lesson)) {
      for (final term in p.terms.keys) {
        expect(seen.add(term), isTrue, reason: '"$term" iki kez tanımlanmış');
      }
    }
  });

  test('week 3 actually tests scale degrees', () {
    expect(earWeekByNumber(3).exercises, contains(EarExerciseKind.scaleDegree));
    expect(earKindsIntroducedBy(5), contains(EarExerciseKind.scaleDegree));
  });
}
