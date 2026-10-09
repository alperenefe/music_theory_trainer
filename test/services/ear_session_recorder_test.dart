import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/ear_exercise_kind.dart';
import 'package:music_theory_trainer/models/ear_session_result.dart';
import 'package:music_theory_trainer/services/ear_session_recorder.dart';
import 'package:music_theory_trainer/services/practice_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  EarSessionResult session(
    DateTime at, {
    EarSessionMode mode = EarSessionMode.practice,
  }) =>
      EarSessionResult(
        kind: EarExerciseKind.intervalBlind,
        weekNumber: 1,
        totalQuestions: 10,
        correctCount: 9,
        errorsBySubtype: const {'interval_minor3': 1},
        durationSeconds: 90,
        completedAt: at,
        mode: mode,
      );

  test('first ever session is persisted (regression: progress list was empty)', () async {
    final repo = PracticePrefsRepository();
    final outcome = await EarSessionRecorder(repo).record(session(DateTime(2026, 9, 1, 9)));

    expect(outcome.after.totalQuestions, 10);
    final prefs = await repo.load();
    expect(prefs.earWeekProgress, hasLength(12));
    expect(prefs.earWeekProgress.first.totalQuestions, 10);
    expect(prefs.earWeekProgress.first.errorsBySubtype['interval_minor3'], 1);
    expect(prefs.earSessionHistory, hasLength(1));
  });

  test('reports week completion and unlocked week', () async {
    final repo = PracticePrefsRepository();
    final recorder = EarSessionRecorder(repo);
    await recorder.record(session(DateTime(2026, 9, 1, 9)));
    await recorder.record(session(DateTime(2026, 9, 2, 9)));
    await recorder.record(session(DateTime(2026, 9, 3, 9)));
    // Diğer barajlar geçilse de boss yenilmeden hafta tamamlanmaz.
    final outcome = await recorder.record(
      session(DateTime(2026, 9, 3, 10), mode: EarSessionMode.boss),
    );

    expect(outcome.weekJustCompleted, isTrue);
    expect(outcome.unlockedWeek?.weekNumber, 2);
    final prefs = await repo.load();
    expect(prefs.earWeekProgress[1].isUnlocked, isTrue);
    expect(
      prefs.earSessionHistory.first.completedAt,
      DateTime(2026, 9, 3, 10),
    );
  });

  test('history is capped', () async {
    final repo = PracticePrefsRepository();
    final recorder = EarSessionRecorder(repo);
    for (var i = 0; i < EarSessionRecorder.maxHistory + 5; i++) {
      await recorder.record(session(DateTime(2026, 9, 1, 9).add(Duration(minutes: i))));
    }
    final prefs = await repo.load();
    expect(prefs.earSessionHistory, hasLength(EarSessionRecorder.maxHistory));
  });

  test('saveReflection persists confidence and hardest area', () async {
    final repo = PracticePrefsRepository();
    await EarSessionRecorder(repo).saveReflection(
      weekNumber: 1,
      confidence: 4,
      hardestArea: 'Akor geçiş hızı',
    );
    final prefs = await repo.load();
    final w1 = prefs.earWeekProgress.first;
    expect(w1.confidence, 4);
    expect(w1.hardestArea, 'Akor geçiş hızı');
  });
}
