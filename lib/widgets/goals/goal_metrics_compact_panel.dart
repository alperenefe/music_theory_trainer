import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

/// Tek panelde üç hedef kaydırıcısı (hedef ekranı — açık etkinlik).
final class GoalMetricsCompactPanel extends StatelessWidget {
  const GoalMetricsCompactPanel({
    super.key,
    required this.targetCount,
    required this.accuracyPercent,
    required this.maxAvgMs,
    required this.onTargetChanged,
    required this.onAccuracyChanged,
    required this.onSpeedChanged,
  });

  final int targetCount;
  final int accuracyPercent;
  final int maxAvgMs;
  final ValueChanged<int> onTargetChanged;
  final ValueChanged<int> onAccuracyChanged;
  final ValueChanged<int> onSpeedChanged;

  @override
  Widget build(BuildContext context) {
    final sec = (maxAvgMs / 1000).toStringAsFixed(1);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.slate900.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: DesignTokens.borderSubtle),
      ),
      child: Column(
        children: [
          _GoalMetricRow(
            label: AppStrings.goalTargetSection,
            value: '$targetCount',
            valueColor: DesignTokens.white,
            slider: _denseSlider(
              context,
              value: targetCount.clamp(50, 5000).toDouble(),
              min: 50,
              max: 5000,
              divisions: 99,
              onChanged: (v) => onTargetChanged(v.round()),
            ),
          ),
          const _RowDivider(),
          _GoalMetricRow(
            label: AppStrings.goalAccuracyTargetSection,
            value: '$accuracyPercent%',
            valueColor: DesignTokens.green400,
            slider: _denseSlider(
              context,
              value: accuracyPercent.toDouble(),
              min: 50,
              max: 100,
              divisions: 50,
              onChanged: (v) => onAccuracyChanged(v.round()),
            ),
          ),
          const _RowDivider(),
          _GoalMetricRow(
            label: AppStrings.goalSpeedTargetSection,
            value: '$sec sn',
            valueColor: DesignTokens.violet400,
            hint: AppStrings.goalSpeedTargetHintShort,
            slider: _denseSlider(
              context,
              value: maxAvgMs.toDouble(),
              min: 800,
              max: 8000,
              divisions: 36,
              onChanged: (v) => onSpeedChanged(v.round()),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _denseSlider(
    BuildContext context, {
    required double value,
    required double min,
    required double max,
    required int divisions,
    required ValueChanged<double> onChanged,
  }) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
      ),
    );
  }
}

final class _GoalMetricRow extends StatelessWidget {
  const _GoalMetricRow({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.slider,
    this.hint,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Widget slider;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: t.labelMedium?.copyWith(
                        color: DesignTokens.slate400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        hint!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: t.labelSmall?.copyWith(
                          color: DesignTokens.slate600,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                value,
                style: t.titleMedium?.copyWith(
                  color: valueColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          slider,
        ],
      ),
    );
  }
}

final class _RowDivider extends StatelessWidget {
  const _RowDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: DesignTokens.borderSubtle.withValues(alpha: 0.6),
    );
  }
}
