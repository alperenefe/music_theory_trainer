import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/ear_exercise_kind.dart';
import 'package:music_theory_trainer/models/ear_session_result.dart';
import 'package:music_theory_trainer/models/weekly_progress.dart';

void main() {
  test('WeeklyProgress round-trips new fields', () {
    final p = WeeklyProgress(
      weekNumber: 3,
      isUnlocked: true,
      bestAccuracy: 0.9,
      totalQuestions: 30,
      totalCorrect: 27,
      unlockedAt: DateTime(2026, 9, 1),
      errorsBySubtype: const {'chord_minor': 2},
      activeDays: const ['2026-09-01', '2026-09-02'],
      bossCleared: true,
      confidence: 4,
      hardestArea: 'Akor geçiş hızı',
    );
    final back = WeeklyProgress.fromJson(p.toJson());
    expect(back.weekNumber, 3);
    expect(back.activeDays, ['2026-09-01', '2026-09-02']);
    expect(back.bossCleared, isTrue);
    expect(back.confidence, 4);
    expect(back.hardestArea, 'Akor geçiş hızı');
    expect(back.errorsBySubtype, {'chord_minor': 2});
  });

  test('WeeklyProgress reads legacy JSON without new fields', () {
    final back = WeeklyProgress.fromJson({'weekNumber': 2, 'isUnlocked': true});
    expect(back.activeDays, isEmpty);
    expect(back.bossCleared, isFalse);
    expect(back.confidence, isNull);
  });

  test('EarSessionResult round-trips mode and defaults legacy to practice', () {
    final r = EarSessionResult(
      kind: EarExerciseKind.cadenceRecognition,
      weekNumber: 8,
      totalQuestions: 15,
      correctCount: 13,
      durationSeconds: 200,
      completedAt: DateTime(2026, 9, 5, 18),
      mode: EarSessionMode.boss,
    );
    final back = EarSessionResult.fromJson(r.toJson());
    expect(back.mode, EarSessionMode.boss);
    expect(back.kind, EarExerciseKind.cadenceRecognition);

    final legacy = r.toJson()..remove('mode');
    expect(EarSessionResult.fromJson(legacy).mode, EarSessionMode.practice);
  });
}
