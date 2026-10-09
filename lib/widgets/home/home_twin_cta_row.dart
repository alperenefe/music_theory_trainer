import 'package:flutter/material.dart';
import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../motion/motion_entrance.dart';

/// Ana sayfa kısayolu: Hedefler.
///
/// Kulak eğitimine buradan ayrı bir "Kulak Eğitimi" düğmesiyle de
/// gidiliyordu — hemen üstteki [EarTrainingBanner] zaten aynı hedefe
/// giden, çok daha görünür ve bilgilendirici (hafta/ilerleme gösteren) bir
/// giriş noktası. İkisi yan yana aynı ekranda tekrar ediyordu; bu satır
/// artık sadece Hedefler'e gidiyor.
final class HomeTwinCtaRow extends StatelessWidget {
  const HomeTwinCtaRow({super.key, required this.onGoalsTap});

  final VoidCallback onGoalsTap;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: onSurface,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.6,
    );

    return _CtaButton(
      key: const Key('home_card_hedefler'),
      label: AppStrings.homeCtaGoals,
      icon: Icons.flag_rounded,
      filled: false,
      onTap: onGoalsTap,
      labelStyle: labelStyle,
    ).entranceFadeSlide(
      context,
      slideY: 0.06,
      delay: const Duration(milliseconds: 80),
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final outlineFill = Theme.of(context).colorScheme.surfaceContainerHighest;
    final outlineBorder = dark
        ? DesignTokens.slate700
        : const Color(0xFFE2E8F0);
    final iconColor = filled ? DesignTokens.white : Theme.of(context).colorScheme.onSurface;
    final textStyle = filled
        ? labelStyle?.copyWith(color: DesignTokens.white)
        : labelStyle;
    return Material(
      color: filled ? background : outlineFill,
      elevation: filled ? 4 : 0,
      shadowColor: filled ? background?.withValues(alpha: 0.45) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.md),
        side: filled
            ? BorderSide.none
            : BorderSide(color: outlineBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
