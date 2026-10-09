import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/models/ear_exercise_kind.dart';
import 'package:music_theory_trainer/models/ear_session_result.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:music_theory_trainer/models/weekly_progress.dart';
import 'package:music_theory_trainer/services/ear_curriculum_service.dart';
import 'package:music_theory_trainer/services/weak_spot_analyzer.dart';
import 'package:music_theory_trainer/services/weekly_mastery_gate.dart';

EarSessionResult _s(int correct, int day, {EarSessionMode mode = EarSessionMode.practice}) =>
    EarSessionResult(
      kind: EarExerciseKind.intervalBlind,
      weekNumber: 1,
      totalQuestions: 10,
      correctCount: correct,
      durationSeconds: 60,
      completedAt: DateTime(2026, 9, day, 12),
      mode: mode,
    );

void main() {
  group('rolling accuracy gate', () {
    final initial = const EarCurriculumService().ensureProgressList(const []);

    test('one lucky session does not carry a week on its own', () {
      var list = initial;
      // Şanslı bir boss turu (%90), ardından iki zayıf tur (%50).
      list = WeeklyMasteryGate.applySession(
        progressList: list,
        session: _s(9, 1, mode: EarSessionMode.boss),
      );
      list = WeeklyMasteryGate.applySession(progressList: list, session: _s(5, 2));
      list = WeeklyMasteryGate.applySession(progressList: list, session: _s(5, 3));

      final w1 = list.first;
      expect(w1.bestAccuracy, closeTo(0.9, 1e-9));
      expect(w1.gateAccuracy, closeTo(0.6333, 1e-3));
      expect(w1.bossCleared, isTrue);
      expect(w1.activeDays, hasLength(3));
      expect(w1.isCompleted, isFalse, reason: 'ortalama %80 barajının altında');
    });

    test('average uses only the last 3 sessions', () {
      var list = initial;
      for (final (c, d) in [(4, 1), (4, 2), (9, 3), (9, 4), (9, 5)]) {
        list = WeeklyMasteryGate.applySession(progressList: list, session: _s(c, d));
      }
      expect(list.first.recentAccuracies, hasLength(5));
      expect(list.first.gateAccuracy, closeTo(0.9, 1e-9));
    });

    test('legacy progress without recent accuracies falls back to best session', () {
      const legacy = WeeklyProgress(weekNumber: 1, isUnlocked: true, bestAccuracy: 0.82);
      expect(legacy.gateAccuracy, 0.82);
    });

    test('recent accuracies survive JSON round trip', () {
      const p = WeeklyProgress(weekNumber: 2, recentAccuracies: [0.5, 0.8, 0.9]);
      final back = WeeklyProgress.fromJson(p.toJson());
      expect(back.recentAccuracies, [0.5, 0.8, 0.9]);
    });
  });

  group('interval anchors', () {
    test('round trip keeps up and down anchors separately', () {
      final key = PracticePrefs.anchorKey('interval_minor3');
      final down = PracticePrefs.anchorKey('interval_minor3', descending: true);
      expect(down, 'interval_minor3_down');
      final prefs = PracticePrefs(intervalAnchors: {key: 'Seven Nation Army', down: 'Küçük Kurbağa'});
      final back = PracticePrefs.fromJson(prefs.toJson());
      expect(back.intervalAnchors[key], 'Seven Nation Army');
      expect(back.intervalAnchors[down], 'Küçük Kurbağa');
    });

    test('blank and non-string anchors are dropped, long ones trimmed', () {
      final back = PracticePrefs.fromJson({
        'intervalAnchors': {
          'interval_major3': '   ',
          'interval_octave': 42,
          'interval_perfect5': 'x' * 200,
        },
      });
      expect(back.intervalAnchors.containsKey('interval_major3'), isFalse);
      expect(back.intervalAnchors.containsKey('interval_octave'), isFalse);
      expect(back.intervalAnchors['interval_perfect5']!.length, PracticePrefs.maxAnchorLength);
    });
  });

  group('subtype accuracy', () {
    const analyzer = WeakSpotAnalyzer();

    test('computes per-subtype accuracy, lowest first, ignoring tiny samples', () {
      final sessions = [
        EarSessionResult(
          kind: EarExerciseKind.intervalBlind,
          weekNumber: 1,
          totalQuestions: 12,
          correctCount: 8,
          errorsBySubtype: const {'interval_minor3': 3, 'interval_major3': 1},
          attemptsBySubtype: const {
            'interval_minor3': 5,
            'interval_major3': 5,
            'interval_octave': 2,
          },
          durationSeconds: 60,
          completedAt: DateTime(2026, 9, 1),
        ),
      ];
      final acc = analyzer.subtypeAccuracy(sessions);
      expect(acc.map((a) => a.subtype), ['interval_minor3', 'interval_major3']);
      expect(acc.first.accuracy, closeTo(0.4, 1e-9));
      expect(acc.first.correct, 2);
      expect(acc.last.accuracy, closeTo(0.8, 1e-9));
    });
  });
}
