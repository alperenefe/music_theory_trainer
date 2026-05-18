import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

final class HomeRouteCard extends StatelessWidget {
  const HomeRouteCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    required this.index,
    this.showStartLink = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final int index;
  final bool showStartLink;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
          padding: AppSpacing.cardPad,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: onTap,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.sm + 2),
                        child: Icon(icon, color: accent, size: 26),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: t.titleMedium?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            subtitle,
                            style: t.bodySmall?.copyWith(
                              color: DesignTokens.slate400,
                              height: 1.4,
                            ),
                          ),
                          if (showStartLink) ...[
                            const SizedBox(height: AppSpacing.md),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                AppStrings.start,
                                style: t.labelLarge?.copyWith(
                                  color: DesignTokens.blue500,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: DesignTokens.slate500.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.medium, curve: AppMotion.curve)
        .slideY(
          begin: 0.06,
          end: 0,
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          delay: (60 * index).ms,
        );
  }
}
