import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

final class WeekTheoryCard extends StatelessWidget {
  const WeekTheoryCard({
    super.key,
    required this.week,
    this.onPlayAudioDemo,
  });

  final EarWeek week;
  final VoidCallback? onPlayAudioDemo;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final accent = week.isConsolidation ? DesignTokens.earGold : DesignTokens.blue500;
    final accentText = week.isConsolidation ? p.gold : p.info;

    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: week.isConsolidation ? accent.withValues(alpha: 0.6) : p.border,
          width: week.isConsolidation ? 1.6 : 1.0,
        ),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 14, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: accent.withValues(alpha: 0.7)),
                ),
                child: Text(
                  week.isConsolidation
                      ? '⭐ ${EarStrings.consolidationBadge}'
                      : EarStrings.weekLabel(week.weekNumber).toUpperCase(),
                  style: t.labelSmall?.copyWith(
                    color: accentText,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (onPlayAudioDemo != null)
                IconButton.filledTonal(
                  onPressed: onPlayAudioDemo,
                  icon: const Icon(Icons.volume_up_rounded, size: 20),
                  tooltip: EarStrings.demoTooltip,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            week.title,
            style: t.titleLarge?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            week.subtitle,
            style: t.bodyMedium?.copyWith(color: p.textMuted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.surfaceSunken,
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: DesignTokens.earAmber, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        EarStrings.theoryTitle,
                        style: t.labelMedium?.copyWith(
                          color: p.textSecondary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        week.theoryBrief,
                        style: t.bodyMedium?.copyWith(color: p.textPrimary, height: 1.45),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
