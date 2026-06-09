import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = Theme.of(context).colorScheme.surfaceContainerHighest;
    final border = dark
        ? DesignTokens.borderSubtle.withValues(alpha: 0.9)
        : const Color(0xFFE2E8F0);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface.withValues(alpha: dark ? 0.92 : 1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: border),
        boxShadow: dark
            ? [
                BoxShadow(
                  color: DesignTokens.glowBlue,
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Padding(padding: padding ?? AppSpacing.cardPad, child: child),
    );
  }
}
