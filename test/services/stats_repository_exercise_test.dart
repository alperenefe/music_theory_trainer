import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/services/stats_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await (await SharedPreferences.getInstance()).clear();
  });

  test('recentForExercise son 500 ile sınırlar', () async {
    final repo = StatsRepository();
    for (var i = 0; i < 600; i++) {
      await repo.append(
        PracticeAttempt(
          exercise: AppStrings.exerciseMcq,
          midi: 60,
          correct: true,
          latencyMs: 10,
          atMillis: i,
        ),
      );
    }
    await repo.append(
      PracticeAttempt(
        exercise: AppStrings.exercisePlacement,
        midi: 62,
        correct: false,
        latencyMs: 20,
        atMillis: 9999,
      ),
    );
    final rows = await repo.recentForExercise(AppStrings.exerciseMcq, limit: 500);
    expect(rows.length, 500);
    expect(rows.first.atMillis, 100);
    expect(rows.every((r) => r.exercise == AppStrings.exerciseMcq), isTrue);
  });

  test('clearExercise yalnızca ilgili kayıtları siler', () async {
    final repo = StatsRepository();
    await repo.append(
      PracticeAttempt(
        exercise: AppStrings.exerciseMcq,
        midi: 60,
        correct: true,
        latencyMs: 10,
        atMillis: 1,
      ),
    );
    await repo.append(
      PracticeAttempt(
        exercise: AppStrings.exercisePlacement,
        midi: 62,
        correct: true,
        latencyMs: 10,
        atMillis: 2,
      ),
    );
    await repo.clearExercise(AppStrings.exerciseMcq);
    final all = await repo.load();
    expect(all.length, 1);
    expect(all.single.exercise, AppStrings.exercisePlacement);
  });
}
