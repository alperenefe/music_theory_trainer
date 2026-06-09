import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/stats_summary.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';
import 'accuracy_progress_bar.dart';

final class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({
    super.key,
    required this.summary,
  });

  final StatsSummary summary;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    if (summary.total == 0) {
      return SoftCard(
        child: Column(
          children: [
            Icon(
              Icons.insights_outlined,
              size: 48,
              color: DesignTokens.slate500,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.noData,
              textAlign: TextAlign.center,
              style: t.titleSmall?.copyWith(
                color: DesignTokens.slate300,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.emptyStateHint,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(
                color: DesignTokens.slate400,
                height: 1.45,
              ),
            ),
          ],
        ),
      );
    }

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StatsMetricRow(label: AppStrings.attempts, value: '${summary.total}'),
          _AccuracyMetricBlock(accuracy: summary.accuracy),
          StatsMetricRow(
            label: AppStrings.avgTime,
            value: summary.avgLatencyMs == null
                ? '—'
                : '${summary.avgLatencyMs} ms',
          ),
        ],
      ),
    );
  }
}

final class _AccuracyMetricBlock extends StatelessWidget {
  const _AccuracyMetricBlock({required this.accuracy});

  final double accuracy;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = (accuracy * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.accuracy,
                  style: t.bodyMedium?.copyWith(color: DesignTokens.slate400),
                ),
              ),
              Text(
                '$pct%',
                style: t.titleMedium?.copyWith(
                  color: DesignTokens.green400,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          AccuracyProgressBar(accuracy: accuracy),
        ],
      ),
    );
  }
}

final class StatsMetricRow extends StatelessWidget {
  const StatsMetricRow({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: t.bodyMedium?.copyWith(color: DesignTokens.slate400),
            ),
          ),
          Text(
            value,
            style: t.titleMedium?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
