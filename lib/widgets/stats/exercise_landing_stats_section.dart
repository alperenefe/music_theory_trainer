import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_attempt.dart';
import '../../services/stats_summary.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';
import '../motion/pressable_scale.dart';
import 'stats_summary_card.dart';

/// Egzersiz girişinde bu etkinliğe özel özet + detay açma.
final class ExerciseLandingStatsSection extends StatelessWidget {
  const ExerciseLandingStatsSection({
    super.key,
    required this.rows,
    required this.goalPeriodActive,
    required this.onOpenStats,
  });

  final List<PracticeAttempt> rows;
  final bool goalPeriodActive;
  final VoidCallback onOpenStats;

  String get _subtitle {
    if (rows.isEmpty) {
      return AppStrings.exerciseStatsEmpty;
    }
    if (goalPeriodActive) {
      return AppStrings.exerciseStatsGoalPeriod;
    }
    return AppStrings.exerciseStatsWindow(rows.length);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final summary = summarizeAttempts(rows);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PressableScale(
          onTap: onOpenStats,
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.insights_outlined,
                      size: 20,
                      color: DesignTokens.blue500,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        AppStrings.exerciseStatsTitle,
                        style: t.titleSmall?.copyWith(
                          color: DesignTokens.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: DesignTokens.slate500,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _subtitle,
                  style: t.bodySmall?.copyWith(
                    color: DesignTokens.slate500,
                    height: 1.35,
                  ),
                ),
                if (summary.total > 0) ...[
                  const SizedBox(height: AppSpacing.sm),
                  StatsSummaryCard(summary: summary),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: onOpenStats,
          icon: const Icon(Icons.bar_chart_rounded),
          label: Text(AppStrings.exerciseStatsTitle),
        ),
      ],
    );
  }
}
