import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/completed_goal_record.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/cards/soft_card.dart';
import '../goal_completion_screen.dart';

final class CompletedGoalsHistorySection extends StatelessWidget {
  const CompletedGoalsHistorySection({
    super.key,
    required this.records,
  });

  final List<CompletedGoalRecord> records;

  static String _formatDate(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    final m = months[d.month - 1];
    return '${d.day} $m ${d.year}';
  }

  void _open(BuildContext context, CompletedGoalRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GoalCompletionScreen(report: record.toReport()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.goalCompletedHistorySection,
          style: t.titleSmall?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (records.isEmpty)
          Text(
            AppStrings.goalCompletedHistoryEmpty,
            style: t.bodyMedium?.copyWith(color: DesignTokens.slate400),
          )
        else
          ...records.map((r) {
            final pct = (r.accuracy * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: SoftCard(
                padding: EdgeInsets.zero,
                child: InkWell(
                  onTap: () => _open(context, r),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  child: Padding(
                    padding: AppSpacing.cardPad,
                    child: Row(
                      children: [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: DesignTokens.green400.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.goalTitle,
                                style: t.titleSmall?.copyWith(
                                  color: DesignTokens.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                AppStrings.goalCompletedHistoryLine(
                                  date: _formatDate(r.completedAtMillis),
                                  target: r.target,
                                  accuracyPercent: pct,
                                ),
                                style: t.bodySmall?.copyWith(
                                  color: DesignTokens.slate400,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: DesignTokens.slate500,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }
}
