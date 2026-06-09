import 'package:flutter/material.dart';

import '../../config/goal_kind.dart';
import '../../models/exercise_goal.dart';
import '../../theme/app_spacing.dart';
import 'per_activity_goal_tile.dart';

/// Etkinlik hedefleri: kapalılar iki sütun, açık olan tam genişlik + slider.
final class PerActivityGoalsSection extends StatelessWidget {
  const PerActivityGoalsSection({
    super.key,
    required this.goalsByKind,
    required this.onGoalChanged,
  });

  final Map<String, ExerciseGoal> goalsByKind;
  final void Function(String kind, ExerciseGoal goal) onGoalChanged;

  ExerciseGoal _goalFor(String kind) =>
      goalsByKind[kind] ?? const ExerciseGoal();

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    final kinds = GoalKind.practiceKinds;
    var i = 0;
    while (i < kinds.length) {
      final kind = kinds[i];
      final goal = _goalFor(kind);
      if (goal.enabled) {
        children.add(
          PerActivityGoalTile(
            kind: kind,
            goal: goal,
            onChanged: (g) => onGoalChanged(kind, g),
          ),
        );
        children.add(const SizedBox(height: AppSpacing.md));
        i++;
        continue;
      }

      final nextKind = i + 1 < kinds.length ? kinds[i + 1] : null;
      final nextGoal =
          nextKind != null ? _goalFor(nextKind) : const ExerciseGoal();
      if (nextKind != null && !nextGoal.enabled) {
        children.add(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PerActivityGoalTile(
                  kind: kind,
                  goal: goal,
                  compact: true,
                  onChanged: (g) => onGoalChanged(kind, g),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: PerActivityGoalTile(
                  kind: nextKind,
                  goal: nextGoal,
                  compact: true,
                  onChanged: (g) => onGoalChanged(nextKind, g),
                ),
              ),
            ],
          ),
        );
        children.add(const SizedBox(height: AppSpacing.sm));
        i += 2;
        continue;
      }

      children.add(
        PerActivityGoalTile(
          kind: kind,
          goal: goal,
          compact: true,
          onChanged: (g) => onGoalChanged(kind, g),
        ),
      );
      children.add(const SizedBox(height: AppSpacing.sm));
      i++;
    }
    if (children.isNotEmpty) {
      children.removeLast();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}
