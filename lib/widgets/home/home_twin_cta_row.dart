import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

/// Ana sayfa alt kısayollar: Akort (dolu cyan) + Hedefler (outline).
final class HomeTwinCtaRow extends StatelessWidget {
  const HomeTwinCtaRow({
    super.key,
    required this.onTunerTap,
    required this.onGoalsTap,
  });

  static const _tunerCyan = Color(0xFF0891B2);

  final VoidCallback onTunerTap;
  final VoidCallback onGoalsTap;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: DesignTokens.white,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    );

    return Row(
        children: [
          Expanded(
            child: _CtaButton(
              key: const Key('home_card_akort'),
              label: AppStrings.homeCtaTuner,
              icon: Icons.tune_rounded,
              filled: true,
              background: _tunerCyan,
              onTap: onTunerTap,
              labelStyle: labelStyle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _CtaButton(
              key: const Key('home_card_hedefler'),
              label: AppStrings.homeCtaGoals,
              icon: Icons.flag_rounded,
              filled: false,
              onTap: onGoalsTap,
              labelStyle: labelStyle,
            ),
          ),
        ],
    );
  }
}

final class _CtaButton extends StatelessWidget {
  const _CtaButton({
    super.key,
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    required this.labelStyle,
    this.background,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  final TextStyle? labelStyle;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? background : DesignTokens.slate800,
      elevation: filled ? 4 : 0,
      shadowColor: filled ? background?.withValues(alpha: 0.45) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: filled
            ? BorderSide.none
            : const BorderSide(color: DesignTokens.slate700),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: DesignTokens.white, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}
