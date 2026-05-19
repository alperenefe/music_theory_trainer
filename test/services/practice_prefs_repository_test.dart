import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/goal_kind.dart';
import 'package:music_theory_trainer/models/exercise_goal.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:music_theory_trainer/services/practice_prefs_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    await p.clear();
  });

  test('roundtrip', () async {
    final r = PracticePrefsRepository();
    const a = PracticePrefs(
      poolMinMidi: 62,
      poolMaxMidi: 79,
      exerciseGoals: {
        GoalKind.placement: ExerciseGoal(
          enabled: true,
          target: 120,
          progress: 5,
          startedAtMillis: 999,
        ),
      },
      soundEnabled: true,
      onboardingDone: true,
    );
    await r.save(a);
    final b = await r.load();
    expect(b.poolMinMidi, 62);
    expect(b.poolMaxMidi, 79);
    expect(b.exerciseGoals[GoalKind.placement]!.target, 120);
    expect(b.exerciseGoals[GoalKind.placement]!.progress, 5);
    expect(b.soundEnabled, isTrue);
    expect(b.onboardingDone, isTrue);
  });

  test('withGoal ilerleme ve enabled korunur', () async {
    final r = PracticePrefsRepository();
    await r.save(
      const PracticePrefs(
        exerciseGoals: {
          GoalKind.mcq: ExerciseGoal(
            enabled: true,
            target: 2,
            progress: 0,
          ),
        },
      ),
    );
    var p = await r.load();
    final goal = p.goalForKind(GoalKind.mcq)!;
    await r.save(p.withGoal(GoalKind.mcq, goal.copyWith(progress: 1)));
    p = await r.load();
    expect(p.goalForKind(GoalKind.mcq), isNotNull);
    expect(p.exerciseGoals[GoalKind.mcq]!.progress, 1);
    expect(p.exerciseGoals[GoalKind.mcq]!.enabled, isTrue);
  });
}
