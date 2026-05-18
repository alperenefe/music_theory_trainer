import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/attempt_accuracy_series.dart';

void main() {
  group('attemptAccuracySeries', () {
    test('boş liste boş seri döner', () {
      expect(attemptAccuracySeries([]), isEmpty);
    });

    test('zaman sırasına göre sıralar ve pencere ortalaması', () {
      final rows = [
        const PracticeAttempt(
          exercise: 'x',
          midi: 60,
          correct: false,
          latencyMs: 10,
          atMillis: 100,
        ),
        const PracticeAttempt(
          exercise: 'x',
          midi: 60,
          correct: true,
          latencyMs: 10,
          atMillis: 200,
        ),
        const PracticeAttempt(
          exercise: 'x',
          midi: 60,
          correct: true,
          latencyMs: 10,
          atMillis: 300,
        ),
      ];
      final s = attemptAccuracySeries(rows, maxPoints: 40, window: 5);
      expect(s.length, 3);
      expect(s[0], 0.0);
      expect(s[1], 0.5);
      expect(s[2], closeTo(2 / 3, 1e-9));
    });

    test('maxPoints son N denemeyi alır', () {
      final rows = List.generate(
        10,
        (i) => PracticeAttempt(
          exercise: 'x',
          midi: 60,
          correct: i.isEven,
          latencyMs: 1,
          atMillis: i * 10,
        ),
      );
      final s = attemptAccuracySeries(rows, maxPoints: 4, window: 2);
      expect(s.length, 4);
    });
  });
}
