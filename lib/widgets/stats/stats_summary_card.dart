import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/stats_summary.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';
import 'attempt_sparkline.dart';

final class StatsSummaryCard extends StatelessWidget {
  const StatsSummaryCard({
    super.key,
    required this.summary,
    required this.series,
  });

  final StatsSummary summary;
  final List<double> series;

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
          StatsMetricRow(
            label: AppStrings.accuracy,
            value: '${(summary.accuracy * 100).round()}%',
          ),
          StatsMetricRow(
            label: AppStrings.avgTime,
            value: summary.avgLatencyMs == null
                ? '—'
                : '${summary.avgLatencyMs} ms',
          ),
          if (series.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              AppStrings.statsActivity,
              style: t.labelLarge?.copyWith(
                color: DesignTokens.slate300,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            AttemptSparkline(series: series),
          ],
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
