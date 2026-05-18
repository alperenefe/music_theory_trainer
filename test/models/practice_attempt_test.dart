import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';

void main() {
  group('PracticeAttempt', () {
    test('toJson fromJson turu', () {
      const a = PracticeAttempt(
        exercise: 'x',
        midi: 66,
        correct: true,
        latencyMs: 120,
        atMillis: 1700,
      );
      final b = PracticeAttempt.fromJson(a.toJson());
      expect(b.exercise, a.exercise);
      expect(b.midi, a.midi);
      expect(b.correct, a.correct);
      expect(b.latencyMs, a.latencyMs);
      expect(b.atMillis, a.atMillis);
    });

    test('fromJson num alanlarını int yapar', () {
      final b = PracticeAttempt.fromJson({
        'exercise': 'y',
        'midi': 60.0,
        'correct': false,
        'latencyMs': 99.0,
        'atMillis': 2000.0,
      });
      expect(b.midi, 60);
      expect(b.latencyMs, 99);
      expect(b.atMillis, 2000);
    });
  });
}
