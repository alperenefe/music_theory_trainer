import 'package:flutter/material.dart';

import '../../config/guitar_tuner_constants.dart';
import '../../models/guitar_note.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class TunerOpenStringStrip extends StatelessWidget {
  const TunerOpenStringStrip({
    super.key,
    required this.textTheme,
    required this.listening,
    required this.hasPitch,
    required this.autoStringIndex,
  });

  final TextTheme textTheme;
  final bool listening;
  final bool hasPitch;
  final int autoStringIndex;

  @override
  Widget build(BuildContext context) {
    final t = textTheme;
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      alignment: WrapAlignment.center,
      children: List.generate(GuitarTunerConstants.stringOrder.length, (i) {
        final s = GuitarTunerConstants.stringOrder[i];
        final active = listening && hasPitch && s == autoStringIndex;
        final n = GuitarNote(string: s, fret: 0);
        final col = GuitarTunerConstants.stringColors[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              colors: [
                col.withValues(alpha: active ? 1 : 0.55),
                col.withValues(alpha: active ? 0.75 : 0.4),
              ],
            ),
            border: Border.all(
              color: active ? DesignTokens.white : Colors.transparent,
              width: active ? 2.5 : 0,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: col.withValues(alpha: 0.45),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                n.noteName,
                style: t.titleLarge?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                n.stringLabel.toUpperCase(),
                style: t.labelSmall?.copyWith(
                  color: DesignTokens.white.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
