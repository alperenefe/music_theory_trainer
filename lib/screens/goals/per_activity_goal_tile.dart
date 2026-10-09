import 'package:flutter/material.dart';

import '../../config/goal_kind.dart';
import '../../models/exercise_goal.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/cards/soft_card.dart';
import '../../widgets/goals/goal_metrics_compact_panel.dart';
import '../../widgets/stats/accuracy_progress_bar.dart';

final class PerActivityGoalTile extends StatelessWidget {
  const PerActivityGoalTile({
    super.key,
    required this.kind,
    required this.goal,
    required this.onChanged,
    this.compact = false,
  });

  final String kind;
  final ExerciseGoal goal;
  final ValueChanged<ExerciseGoal> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final title = GoalKind.titleWithFallback(kind);
    return SoftCard(
      padding: compact ? AppSpacing.cardPadDense : AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            visualDensity:
                compact ? VisualDensity.compact : VisualDensity.standard,
            title: Text(
              title,
              maxLines: compact ? 2 : null,
              overflow: compact ? TextOverflow.ellipsis : null,
              style: (compact ? t.labelLarge : t.titleSmall)?.copyWith(
                color: DesignTokens.white,
                fontWeight: FontWeight.w700,
              ),
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
            // Hedef kartı şimdiye kadar sadece bir AYAR formuydu — ilerlemeyi
            // hiç göstermiyordu. Kullanıcı "ne kadar yaklaştım?" sorusuna tek
            // bakışta cevap alamıyordu. Bu satır o boşluğu dolduruyor.
            Row(
              children: [
                Expanded(
                  child: AccuracyProgressBar(
                    accuracy: goal.target <= 0
                        ? 0
                        : (goal.progress / goal.target).clamp(0.0, 1.0),
                    height: 6,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${goal.progress}/${goal.target}',
                  style: t.labelMedium?.copyWith(
                    color: DesignTokens.slate300,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            GoalMetricsCompactPanel(
              targetCount: goal.target,
              accuracyPercent: goal.accuracyPercent,
              maxAvgMs: goal.maxAvgLatencyMs,
              onTargetChanged: (v) {
                final reset = v != goal.target;
                final now = DateTime.now().millisecondsSinceEpoch;
                onChanged(
                  goal.copyWith(
                    target: v,
                    progress: reset ? 0 : goal.progress,
                    startedAtMillis: reset ? now : goal.startedAtMillis,
                  ),
                );
              },
              onAccuracyChanged: (v) {
                final reset = v != goal.accuracyPercent;
                final now = DateTime.now().millisecondsSinceEpoch;
                onChanged(
                  goal.copyWith(
                    accuracyPercent: v,
                    progress: reset ? 0 : goal.progress,
                    startedAtMillis: reset ? now : goal.startedAtMillis,
                  ),
                );
              },
              onSpeedChanged: (v) {
                final reset = v != goal.maxAvgLatencyMs;
                final now = DateTime.now().millisecondsSinceEpoch;
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
