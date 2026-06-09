import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/stats_summary.dart';

void main() {
  group('summarizeAttempts', () {
    test('boş liste', () {
      final s = summarizeAttempts([]);
      expect(s.total, 0);
      expect(s.correct, 0);
      expect(s.avgLatencyMs, isNull);
      expect(s.midiStats, isEmpty);
    });

    test('toplam doğruluk ve ortalama', () {
      final rows = [
        const PracticeAttempt(
          exercise: 'a',
          midi: 60,
          correct: true,
          latencyMs: 100,
          atMillis: 1,
        ),
        const PracticeAttempt(
          exercise: 'a',
          midi: 60,
          correct: false,
          latencyMs: 200,
          atMillis: 2,
        ),
        const PracticeAttempt(
          exercise: 'a',
          midi: 66,
          correct: true,
          latencyMs: 300,
          atMillis: 3,
        ),
      ];
      final s = summarizeAttempts(rows);
      expect(s.total, 3);
      expect(s.correct, 2);
      expect(s.accuracy, closeTo(2 / 3, 0.0001));
      expect(s.avgLatencyMs, 200);
      expect(s.midiStats.length, 2);
      final m60 = s.midiStats.firstWhere((e) => e.midi == 60);
      expect(m60.total, 2);
      expect(m60.correct, 1);
      expect(m60.avgMs, 150);
    });

    test('notalar dogruluga gore dusukten yuksege', () {
      final rows = [
        const PracticeAttempt(
          exercise: 'a',
          midi: 60,
          correct: true,
          latencyMs: 100,
          atMillis: 1,
        ),
        const PracticeAttempt(
          exercise: 'a',
          midi: 60,
          correct: true,
          latencyMs: 100,
          atMillis: 2,
        ),
        const PracticeAttempt(
          exercise: 'a',
          midi: 62,
          correct: false,
          latencyMs: 100,
          atMillis: 3,
        ),
        const PracticeAttempt(
          exercise: 'a',
          midi: 62,
          correct: false,
          latencyMs: 100,
          atMillis: 4,
        ),
        const PracticeAttempt(
          exercise: 'a',
          midi: 64,
          correct: true,
          latencyMs: 100,
          atMillis: 5,
        ),
      ];
      final s = summarizeAttempts(rows);
      expect(s.midiStats.map((e) => e.midi).toList(), [62, 60, 64]);
      expect(s.midiStats.map((e) => e.accuracy).toList(), [0.0, 1.0, 1.0]);
    });
  });
}
