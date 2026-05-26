import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_strings.dart';
import '../../services/goal_progress_snapshot.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';
import 'activity_goal_progress_strip.dart';

/// İki sütunlu ana menü kartı (ZIP grid).
final class HomeGridCard extends StatelessWidget {
  const HomeGridCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
    required this.index,
    this.goalProgress,
    this.micBadge = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;
  final int index;
  final GoalProgressSnapshot? goalProgress;
  final bool micBadge;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SoftCard(
          padding: EdgeInsets.zero,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadii.lg),
              onTap: onTap,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(color: accent, width: 4),
                  ),
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(AppRadii.lg),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(AppRadii.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Icon(icon, color: accent, size: 22),
                        ),
                      ),
                      const Spacer(),
                      if (micBadge)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: DesignTokens.green400.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: DesignTokens.green400.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.mic_rounded,
                                size: 12,
                                color: DesignTokens.green400,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                AppStrings.homeMicBadge,
                                style: t.labelSmall?.copyWith(
                                  color: DesignTokens.green400,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.titleSmall?.copyWith(
                      color: DesignTokens.white,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: t.bodySmall?.copyWith(
                      color: DesignTokens.slate500,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                  if (goalProgress != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    ActivityGoalProgressStrip(
                      snapshot: goalProgress!,
                      variant: GoalProgressVariant.homeCompact,
                    ),
                  ],
                ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: AppMotion.medium, curve: AppMotion.curve)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: AppMotion.medium,
          curve: AppMotion.curve,
          delay: (40 * index).ms,
        );
  }
}
