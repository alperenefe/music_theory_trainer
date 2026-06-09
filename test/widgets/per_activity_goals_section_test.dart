import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/goal_kind.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/exercise_goal.dart';
import 'package:music_theory_trainer/screens/goals/per_activity_goals_section.dart';

void main() {
  testWidgets('kapalı hedeflerde uzun ipucu yok', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PerActivityGoalsSection(
            goalsByKind: const {
              GoalKind.placement: ExerciseGoal(),
              GoalKind.mcq: ExerciseGoal(),
            },
            onGoalChanged: (_, __) {},
          ),
        ),
      ),
    );
    expect(find.text(AppStrings.placementTitle), findsOneWidget);
    expect(find.textContaining('ana ekranda'), findsNothing);
    expect(find.textContaining('Hedef kapalı'), findsNothing);
  });
}
