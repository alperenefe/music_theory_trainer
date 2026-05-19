import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/stats_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('StatsRepository', () {
    late StatsRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final p = await SharedPreferences.getInstance();
      await p.clear();
      repo = StatsRepository();
    });

    test('append ve load kalıcılığı', () async {
      expect(await repo.load(), isEmpty);
      await repo.append(
        const PracticeAttempt(
          exercise: 'yerlestir',
          midi: 64,
          correct: true,
          latencyMs: 50,
          atMillis: 100,
        ),
      );
      final rows = await repo.load();
      expect(rows.length, 1);
      expect(rows.first.midi, 64);
      expect(rows.first.correct, isTrue);
    });

    test('append en fazla maxStoredAttempts tutar', () async {
      for (var i = 0; i < StatsRepository.maxStoredAttempts + 50; i++) {
        await repo.append(
          PracticeAttempt(
            exercise: 'yerlestir',
            midi: 60 + (i % 12),
            correct: i.isEven,
            latencyMs: 10,
            atMillis: i,
          ),
        );
      }
      final rows = await repo.load();
      expect(rows.length, StatsRepository.maxStoredAttempts);
      expect(rows.first.atMillis, greaterThanOrEqualTo(50));
      expect(rows.last.atMillis, StatsRepository.maxStoredAttempts + 49);
    });

    test('clear temizler', () async {
      await repo.append(
        const PracticeAttempt(
          exercise: 'coktan_secmeli',
          midi: 60,
          correct: false,
          latencyMs: 10,
          atMillis: 1,
        ),
      );
      await repo.clear();
      expect(await repo.load(), isEmpty);
    });
  });
}
