import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class GoalKindChips extends StatelessWidget {
  const GoalKindChips({
    super.key,
    required this.goalKind,
    required this.onChanged,
  });

  final String? goalKind;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.goalKindSection,
          style: t.titleSmall?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            ChoiceChip(
              label: Text(AppStrings.goalNone),
              selected: goalKind == null,
              onSelected: (_) => onChanged(null),
            ),
            ChoiceChip(
              label: Text(AppStrings.placementTitle),
              selected: goalKind == 'placement',
              onSelected: (_) => onChanged('placement'),
            ),
            ChoiceChip(
              label: Text(AppStrings.mcqTitle),
              selected: goalKind == 'mcq',
              onSelected: (_) => onChanged('mcq'),
            ),
            ChoiceChip(
              label: Text(AppStrings.guitarMcqTitle),
              selected: goalKind == 'gitar_mcq',
              onSelected: (_) => onChanged('gitar_mcq'),
            ),
            ChoiceChip(
              label: Text(AppStrings.guitarFindTitle),
              selected: goalKind == 'gitar_bul',
              onSelected: (_) => onChanged('gitar_bul'),
            ),
            ChoiceChip(
              label: Text(AppStrings.guitarPlayTitle),
              selected: goalKind == 'gitar_cal',
              onSelected: (_) => onChanged('gitar_cal'),
            ),
          ],
        ),
      ],
    );
  }
}
