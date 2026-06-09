import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';

final class ResultPill extends StatelessWidget {
  const ResultPill({super.key, required this.correct, required this.visible});

  final bool correct;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final reduced = AppMotion.reduced(context);
    final slideDur = AppMotion.dur(context, AppMotion.medium);
    final fadeDur = AppMotion.dur(context, AppMotion.fast);
    final t = Theme.of(context).textTheme;
    final icon = correct ? Icons.check_circle_rounded : Icons.cancel_rounded;
    final row = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.md),
        color: correct
            ? DesignTokens.green400.withValues(alpha: 0.14)
            : DesignTokens.rose400.withValues(alpha: 0.14),
        border: Border.all(
          color: correct
              ? DesignTokens.green400.withValues(alpha: 0.45)
              : DesignTokens.rose400.withValues(alpha: 0.45),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: correct ? DesignTokens.green400 : DesignTokens.rose400,
            size: 26,
          ),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              correct ? AppStrings.correct : AppStrings.wrong,
              textAlign: TextAlign.center,
              style: t.titleMedium?.copyWith(
                color: correct ? DesignTokens.green400 : DesignTokens.rose400,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
    return AnimatedSlide(
      duration: slideDur,
      curve: AppMotion.curve,
      offset: visible || reduced ? Offset.zero : const Offset(0, 0.08),
      child: AnimatedOpacity(
        duration: fadeDur,
        opacity: visible ? 1 : 0,
        child: IgnorePointer(
          ignoring: !visible,
          child: visible && !reduced
              ? row
                    .animate(key: ValueKey<bool>(correct))
                    .scale(
                      begin: const Offset(0.94, 0.94),
                      end: const Offset(1, 1),
                      duration: 260.ms,
                      curve: Curves.easeOutBack,
                    )
              : row,
        ),
      ),
    );
  }
}
