import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/goal_kind.dart';
import 'package:music_theory_trainer/models/exercise_goal.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';

void main() {
  group('PracticePrefs.fromJson', () {
    test('havuz alanları yoksa porte varsayılanı', () {
      final p = PracticePrefs.fromJson({});
      expect(p.poolMinMidi, PracticePrefs.defaultPoolMinMidi);
      expect(p.poolMaxMidi, PracticePrefs.defaultPoolMaxMidi);
      expect(p.referenceA4Hz, PracticePrefs.defaultReferenceA4Hz);
    });

    test('exerciseGoals roundtrip', () {
      const a = PracticePrefs(
        exerciseGoals: {
          GoalKind.mcq: ExerciseGoal(
            enabled: true,
            target: 100,
            progress: 3,
            startedAtMillis: 1,
            accuracyPercent: 88,
            maxAvgLatencyMs: 2500,
          ),
        },
      );
      final b = PracticePrefs.fromJson(a.toJson());
      final g = b.exerciseGoals[GoalKind.mcq]!;
      expect(g.enabled, isTrue);
      expect(g.target, 100);
      expect(g.progress, 3);
      expect(g.accuracyPercent, 88);
    });

    test('legacy goalKind migration', () {
      final p = PracticePrefs.fromJson({
        'goalKind': 'placement',
        'goalTarget': 200,
        'goalProgress': 4,
        'goalStartedAtMillis': 99,
        'goalAccuracyPercent': 85,
        'goalMaxAvgLatencyMs': 3500,
      });
      final g = p.exerciseGoals['placement']!;
      expect(g.enabled, isTrue);
      expect(g.target, 200);
      expect(g.progress, 4);
    });

    test('soundEnabled ve onboardingDone açıkça okunur', () {
      final p = PracticePrefs.fromJson({
        'soundEnabled': false,
        'onboardingDone': false,
      });
      expect(p.soundEnabled, isFalse);
      expect(p.onboardingDone, isFalse);
    });

    test('referenceA4Hz aşırı değerler sıkıştırılır', () {
      final p = PracticePrefs.fromJson({'referenceA4Hz': 900});
      expect(p.referenceA4Hz, 455);
    });
  });
}
