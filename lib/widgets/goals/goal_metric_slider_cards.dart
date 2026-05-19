import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

final class GoalAccuracySliderCard extends StatelessWidget {
  const GoalAccuracySliderCard({
    super.key,
    required this.percent,
    required this.onChanged,
  });

  final int percent;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.goalAccuracyTargetSection,
            style: t.titleSmall?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            '$percent%',
            style: t.headlineSmall?.copyWith(
              color: DesignTokens.green400,
              fontWeight: FontWeight.w800,
            ),
          ),
          Slider(
            value: percent.toDouble(),
            min: 50,
            max: 100,
            divisions: 50,
            label: '$percent%',
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}

final class GoalSpeedSliderCard extends StatelessWidget {
  const GoalSpeedSliderCard({
    super.key,
    required this.maxAvgMs,
    required this.onChanged,
  });

  final int maxAvgMs;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final sec = (maxAvgMs / 1000).toStringAsFixed(1);
    return SoftCard(
      padding: AppSpacing.cardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            AppStrings.goalSpeedTargetSection,
            style: t.titleSmall?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            AppStrings.goalSpeedTargetHint,
            style: t.bodySmall?.copyWith(color: DesignTokens.slate400),
          ),
          Text(
            '$sec sn ($maxAvgMs ms)',
            style: t.headlineSmall?.copyWith(
              color: DesignTokens.violet400,
              fontWeight: FontWeight.w800,
            ),
          ),
          Slider(
            value: maxAvgMs.toDouble(),
            min: 800,
            max: 8000,
            divisions: 36,
            label: '${maxAvgMs}ms',
            onChanged: (v) => onChanged(v.round()),
          ),
        ],
      ),
    );
  }
}
