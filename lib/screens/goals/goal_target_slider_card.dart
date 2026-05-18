import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/cards/soft_card.dart';

final class GoalTargetSliderCard extends StatelessWidget {
  const GoalTargetSliderCard({
    super.key,
    required this.targetCount,
    required this.onChanged,
  });

  final int targetCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.goalTargetSection,
          style: t.titleSmall?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SoftCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$targetCount',
                textAlign: TextAlign.center,
                style: t.headlineSmall?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Slider.adaptive(
                min: 50,
                max: 5000,
                divisions: 99,
                value: targetCount.clamp(50, 5000).toDouble(),
                onChanged: (v) => onChanged(v.round()),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
