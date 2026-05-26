import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_attempt.dart';
import '../../services/attempt_accuracy_series.dart';
import '../../services/stats_summary.dart';
import '../../theme/app_spacing.dart';
import '../stats/stats_midi_breakdown.dart';
import '../stats/stats_summary_card.dart';
import '../text/section_header.dart';

/// Tek egzersiz için özet (son N deneme).
final class ExerciseStatsPanel extends StatelessWidget {
  const ExerciseStatsPanel({
    super.key,
    required this.rows,
    required this.guitarStyleLabels,
    this.windowSize = 500,
  });

  final List<PracticeAttempt> rows;
  final bool guitarStyleLabels;
  final int windowSize;

  @override
  Widget build(BuildContext context) {
    final summary = summarizeAttempts(rows);
    final series = attemptAccuracySeries(rows);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          title: AppStrings.exerciseStatsTitle,
          subtitle: rows.isEmpty
              ? AppStrings.exerciseStatsEmpty
              : AppStrings.exerciseStatsWindow(windowSize),
        ),
        const SizedBox(height: AppSpacing.md),
        StatsSummaryCard(
          summary: summary,
          series: series,
          layout: StatsSummaryLayout.landingRow,
        ),
        if (summary.total > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          StatsMidiBreakdown(
            midiStats: summary.midiStats,
            guitarStyleLabels: guitarStyleLabels,
          ),
        ],
      ],
    );
  }
}
