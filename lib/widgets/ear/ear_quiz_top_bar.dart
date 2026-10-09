import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/ear_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// Duolingo tarzı quiz üst çubuğu: kapat · ilerleme · can / seri.
final class EarQuizTopBar extends StatelessWidget {
  const EarQuizTopBar({
    super.key,
    required this.onClose,
    required this.progress,
    required this.accentColor,
    required this.counterLabel,
    this.hearts,
    this.maxHearts = 3,
    this.combo = 0,
  });

  final VoidCallback onClose;

  /// 0–1 arası tamamlanma.
  final double progress;
  final Color accentColor;
  final String counterLabel;

  /// Boss modunda kalan can (null: can yok).
  final int? hearts;
  final int maxHearts;
  final int combo;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final duration = AppMotion.dur(context, AppMotion.medium);

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.xs, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: EarStrings.closeTooltip,
            onPressed: onClose,
            icon: Icon(Icons.close_rounded, color: p.textSecondary),
          ),
          Expanded(
            child: Semantics(
              label: counterLabel,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  height: 14,
                  child: Stack(
                    children: [
                      Positioned.fill(child: ColoredBox(color: p.track)),
                      TweenAnimationBuilder<double>(
                        tween: Tween(end: progress.clamp(0.0, 1.0)),
                        duration: duration,
                        curve: AppMotion.curve,
                        builder: (context, value, _) => FractionallySizedBox(
                          widthFactor: value,
                          heightFactor: 1,
                          alignment: Alignment.centerLeft,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            // Üstte ince parlama şeridi (oyunlaştırılmış ilerleme hissi).
                            child: Align(
                              alignment: const Alignment(0, -0.45),
                              child: FractionallySizedBox(
                                widthFactor: 0.94,
                                child: Container(
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (hearts != null)
            _Hearts(hearts: hearts!, max: maxHearts)
          else if (combo >= 2)
            _ComboChip(combo: combo)
          else
            Text(
              counterLabel,
              style: t.labelLarge?.copyWith(color: p.textMuted, fontWeight: FontWeight.w800),
            ),
        ],
      ),
    );
  }
}

final class _Hearts extends StatelessWidget {
  const _Hearts({required this.hearts, required this.max});

  final int hearts;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    return Semantics(
      label: EarStrings.heartsLabel(hearts),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < max; i++)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Icon(
                i < hearts ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22,
                color: i < hearts ? DesignTokens.earRose : p.textMuted,
              ),
            ),
        ],
      ),
    );
  }
}

final class _ComboChip extends StatelessWidget {
  const _ComboChip({required this.combo});

  final int combo;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: DesignTokens.streakOrange.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DesignTokens.streakOrange.withValues(alpha: 0.6)),
      ),
      child: Text(
        '🔥 $combo',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: DesignTokens.streakOrange,
              fontWeight: FontWeight.w900,
            ),
      ),
    );
    if (AppMotion.reduced(context)) return chip;
    return chip
        .animate(key: ValueKey(combo))
        .scaleXY(begin: 1.25, end: 1, duration: 280.ms, curve: Curves.easeOutBack);
  }
}
