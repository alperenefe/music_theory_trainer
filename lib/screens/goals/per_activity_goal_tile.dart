import 'package:flutter/material.dart';

import '../../config/goal_kind.dart';
import '../../l10n/app_strings.dart';
import '../../models/exercise_goal.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/cards/soft_card.dart';
import '../../widgets/goals/goal_metric_slider_cards.dart';
import 'goal_target_slider_card.dart';

final class PerActivityGoalTile extends StatelessWidget {
  const PerActivityGoalTile({
    super.key,
    required this.kind,
    required this.goal,
    required this.onChanged,
  });

  final String kind;
  final ExerciseGoal goal;
  final ValueChanged<ExerciseGoal> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final title = GoalKind.titleWithFallback(kind);
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              title,
              style: t.titleSmall?.copyWith(
                color: DesignTokens.white,
                fontWeight: FontWeight.w700,
              ),
            ),
            subtitle: Text(
              goal.enabled
                  ? AppStrings.goalEnabledHint
                  : AppStrings.goalDisabledHint,
              style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
            ),
            value: goal.enabled,
            onChanged: (on) {
              final now = DateTime.now().millisecondsSinceEpoch;
              onChanged(
                goal.copyWith(
                  enabled: on,
                  progress: on ? 0 : goal.progress,
                  startedAtMillis: on ? now : goal.startedAtMillis,
                ),
              );
            },
          ),
          ),
          if (goal.enabled) ...[
            const SizedBox(height: AppSpacing.sm),
            GoalTargetSliderCard(
              targetCount: goal.target,
              onChanged: (v) {
                final now = DateTime.now().millisecondsSinceEpoch;
                final reset = v != goal.target;
                onChanged(
                  goal.copyWith(
                    target: v,
                    progress: reset ? 0 : goal.progress,
                    startedAtMillis: reset ? now : goal.startedAtMillis,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            GoalAccuracySliderCard(
              percent: goal.accuracyPercent,
              onChanged: (v) {
                final now = DateTime.now().millisecondsSinceEpoch;
                final reset = v != goal.accuracyPercent;
                onChanged(
                  goal.copyWith(
                    accuracyPercent: v,
                    progress: reset ? 0 : goal.progress,
                    startedAtMillis: reset ? now : goal.startedAtMillis,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            GoalSpeedSliderCard(
              maxAvgMs: goal.maxAvgLatencyMs,
              onChanged: (v) {
                final now = DateTime.now().millisecondsSinceEpoch;
                final reset = v != goal.maxAvgLatencyMs;
                onChanged(
                  goal.copyWith(
                    maxAvgLatencyMs: v,
                    progress: reset ? 0 : goal.progress,
                    startedAtMillis: reset ? now : goal.startedAtMillis,
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
