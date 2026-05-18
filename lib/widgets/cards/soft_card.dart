import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class SoftCard extends StatelessWidget {
  const SoftCard({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: DesignTokens.cardBg.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: DesignTokens.borderSubtle.withValues(alpha: 0.9),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.glowBlue,
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(padding: padding ?? AppSpacing.cardPad, child: child),
    );
  }
}
