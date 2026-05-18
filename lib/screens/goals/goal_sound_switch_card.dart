import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/cards/soft_card.dart';

final class GoalSoundSwitchCard extends StatelessWidget {
  const GoalSoundSwitchCard({
    super.key,
    required this.soundEnabled,
    required this.onChanged,
  });

  final bool soundEnabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
      child: SwitchListTile.adaptive(
        value: soundEnabled,
        onChanged: onChanged,
        title: Text(
          soundEnabled ? AppStrings.soundOn : AppStrings.soundOff,
          style: t.titleSmall?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          AppStrings.soundHint,
          style: t.bodySmall?.copyWith(
            color: DesignTokens.slate400,
            height: 1.42,
          ),
        ),
      ),
    );
  }
}
