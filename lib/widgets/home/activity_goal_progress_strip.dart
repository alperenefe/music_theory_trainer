import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/goal_progress_snapshot.dart';
import '../../theme/design_tokens.dart';

enum GoalProgressVariant { full, landingDual, homeCompact }

/// Hedef ilerlemesi: tam (3 çubuk), landing (2), ana grid (1).
final class ActivityGoalProgressStrip extends StatelessWidget {
  const ActivityGoalProgressStrip({
    super.key,
    required this.snapshot,
    this.variant = GoalProgressVariant.full,
  });

  final GoalProgressSnapshot snapshot;
  final GoalProgressVariant variant;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = snapshot;
    switch (variant) {
      case GoalProgressVariant.homeCompact:
        return _MiniBar(
          label: AppStrings.goalActive,
          detail: '${s.attemptsDone}/${s.attemptTarget}',
          progress: s.attemptProgress,
          color: DesignTokens.blue500,
          textStyle: t.labelSmall,
        );
      case GoalProgressVariant.landingDual:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MiniBar(
              label: AppStrings.goalProgressAttempts,
              detail: '${s.attemptsDone}/${s.attemptTarget}',
              progress: s.attemptProgress,
              color: DesignTokens.blue500,
              textStyle: t.labelSmall,
            ),
            const SizedBox(height: 6),
            _MiniBar(
              label: AppStrings.goalProgressAccuracy,
              detail: '${s.accuracyPercent}%/${s.accuracyTargetPercent}%',
              progress: s.accuracyProgress,
              color: DesignTokens.green400,
              textStyle: t.labelSmall,
            ),
          ],
        );
      case GoalProgressVariant.full:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _MiniBar(
              label: AppStrings.goalProgressAttempts,
              detail: '${s.attemptsDone}/${s.attemptTarget}',
              progress: s.attemptProgress,
              color: DesignTokens.blue500,
              textStyle: t.labelSmall,
            ),
            const SizedBox(height: 6),
            _MiniBar(
              label: AppStrings.goalProgressAccuracy,
              detail: '${s.accuracyPercent}%/${s.accuracyTargetPercent}%',
              progress: s.accuracyProgress,
              color: DesignTokens.green400,
              textStyle: t.labelSmall,
            ),
            const SizedBox(height: 6),
            _MiniBar(
              label: AppStrings.goalProgressSpeed,
              detail: s.avgLatencyMs == null
                  ? '—'
                  : '${s.avgLatencyMs}≤${s.maxAvgLatencyTargetMs}ms',
              progress: s.speedProgress,
              color: DesignTokens.violet400,
              textStyle: t.labelSmall,
            ),
          ],
        );
    }
  }
}

final class _MiniBar extends StatelessWidget {
  const _MiniBar({
    required this.label,
    required this.detail,
    required this.progress,
    required this.color,
    required this.textStyle,
  });

  final String label;
  final String detail;
  final double progress;
  final Color color;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: textStyle?.copyWith(
                  color: DesignTokens.slate500,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
            Text(
              detail,
              style: textStyle?.copyWith(
                color: DesignTokens.slate400,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: DesignTokens.slate800,
            color: color,
          ),
        ),
      ],
    );
  }
}
