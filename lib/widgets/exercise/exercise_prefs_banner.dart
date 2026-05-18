import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_prefs.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

final class ExercisePrefsBanner extends StatelessWidget {
  const ExercisePrefsBanner({
    super.key,
    required this.prefs,
    required this.exercise,
  });

  final PracticePrefs prefs;
  final String exercise;

  static String? _goalKindTitle(String? gk) {
    return switch (gk) {
      'placement' => AppStrings.placementTitle,
      'mcq' => AppStrings.mcqTitle,
      'gitar_mcq' => AppStrings.guitarMcqTitle,
      'gitar_bul' => AppStrings.guitarFindTitle,
      'gitar_cal' => AppStrings.guitarPlayTitle,
      _ => null,
    };
  }

  bool _goalMatchesExercise() {
    final gk = prefs.goalKind;
    if (gk == null) {
      return false;
    }
    return (gk == 'placement' && exercise == AppStrings.exercisePlacement) ||
        (gk == 'mcq' && exercise == AppStrings.exerciseMcq) ||
        (gk == 'gitar_mcq' && exercise == AppStrings.exerciseGuitarMcq) ||
        (gk == 'gitar_bul' && exercise == AppStrings.exerciseGuitarFind) ||
        (gk == 'gitar_cal' && exercise == AppStrings.exerciseGuitarPlay);
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final match = _goalMatchesExercise();
    final gk = prefs.goalKind;
    final gkTitle = _goalKindTitle(gk);
    return SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (gk == null)
            Text(
              '${AppStrings.exercisePrefsGoalLine}: ${AppStrings.goalNone}',
              style: t.bodySmall?.copyWith(
                color: DesignTokens.slate400,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            )
          else if (match)
            Text(
              '${AppStrings.exercisePrefsGoalLine}: '
              '${prefs.goalProgress}/${prefs.goalTarget} · $gkTitle',
              style: t.bodySmall?.copyWith(
                color: DesignTokens.slate300,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            )
          else
            Text(
              '${AppStrings.exercisePrefsGoalLine}: $gkTitle · '
              '${AppStrings.exercisePrefsGoalOtherExercise}',
              style: t.bodySmall?.copyWith(
                color: DesignTokens.slate400,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
        ],
      ),
    );
  }
}
