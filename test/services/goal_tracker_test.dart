import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/practice_attempt.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:music_theory_trainer/services/goal_tracker.dart';
import 'package:music_theory_trainer/services/practice_prefs_repository.dart';
import 'package:music_theory_trainer/services/stats_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await p.clear();
  });

  test('hedefe uymayan egzersiz sayılmaz', () async {
    final stats = StatsRepository();
    final prefs = PracticePrefsRepository();
    await prefs.save(
      const PracticePrefs(
        goalKind: 'mcq',
        goalTarget: 2,
        goalProgress: 0,
        goalStartedAtMillis: 100,
      ),
    );
    await stats.append(
      PracticeAttempt(
        exercise: AppStrings.exercisePlacement,
        midi: 60,
        correct: true,
        latencyMs: 10,
        atMillis: 200,
      ),
    );
    final r = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exercisePlacement,
      statsRepo: stats,
      prefsRepo: prefs,
    );
    expect(r, isNull);
    final p = await prefs.load();
    expect(p.goalProgress, 0);
  });

  test('hedef dolunca rapor ve ilerleme sıfırlanır', () async {
    final stats = StatsRepository();
    final prefs = PracticePrefsRepository();
    await prefs.save(
      const PracticePrefs(
        goalKind: 'mcq',
        goalTarget: 2,
        goalProgress: 0,
        goalStartedAtMillis: 500,
      ),
    );
    await stats.append(
      PracticeAttempt(
        exercise: AppStrings.exerciseMcq,
        midi: 64,
        correct: true,
        latencyMs: 100,
        atMillis: 600,
      ),
    );
    expect(
      await GoalTracker.onAttemptRecorded(
        exercise: AppStrings.exerciseMcq,
        statsRepo: stats,
        prefsRepo: prefs,
      ),
      isNull,
    );
    await stats.append(
      PracticeAttempt(
        exercise: AppStrings.exerciseMcq,
        midi: 65,
        correct: false,
        latencyMs: 200,
        atMillis: 700,
      ),
    );
    final report = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseMcq,
      statsRepo: stats,
      prefsRepo: prefs,
    );
    expect(report, isNotNull);
    expect(report!.summary.total, 2);
    expect(report.bestStreak, 1);
    final after = await prefs.load();
    expect(after.goalProgress, 0);
    expect(after.goalStartedAtMillis, greaterThan(500));
  });
}
