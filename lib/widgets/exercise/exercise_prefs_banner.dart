import 'package:flutter/material.dart';

import '../../config/goal_kind.dart';
import '../../l10n/app_strings.dart';
import '../../models/practice_prefs.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

final class ExercisePrefsBanner extends StatelessWidget {
  const ExercisePrefsBanner({
    super.key,
    required this.prefs,
    required this.exercise,
  });

  final PracticePrefs prefs;
  final String exercise;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final kind = GoalKind.kindForExercise(exercise);
    final goal = kind != null ? prefs.goalForKind(kind) : null;
    final title = kind != null ? GoalKind.title(kind) : null;

    String line;
    if (goal == null || title == null) {
      line = '${AppStrings.exercisePrefsGoalLine}: ${AppStrings.goalNone}';
    } else {
      line =
          '${AppStrings.exercisePrefsGoalLine}: '
          '${goal.progress}/${goal.target} · $title · '
          '%${goal.accuracyPercent} · ≤${goal.maxAvgLatencyMs}ms';
    }

    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Text(
        line,
        style: t.bodySmall?.copyWith(
          color: goal == null ? DesignTokens.slate400 : DesignTokens.slate300,
          fontWeight: FontWeight.w600,
          height: 1.35,
        ),
      ),
    );
  }
}
