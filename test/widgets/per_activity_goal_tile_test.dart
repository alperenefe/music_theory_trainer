import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/config/goal_kind.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/exercise_goal.dart';
import 'package:music_theory_trainer/screens/goals/per_activity_goal_tile.dart';

void main() {
  testWidgets('PerActivityGoalTile hedef aç/kapa', (tester) async {
    ExerciseGoal? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PerActivityGoalTile(
            kind: GoalKind.placement,
            goal: const ExerciseGoal(),
            onChanged: (g) => updated = g,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(updated?.enabled, isTrue);
    expect(find.text(AppStrings.placementTitle), findsOneWidget);
  });
}
