import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../services/weekly_mastery_gate.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// Hafta barajının üç kriteri (doğruluk · soru · gün) için ilerleme çubukları.
final class GateCriteriaList extends StatelessWidget {
  const GateCriteriaList({super.key, required this.status, this.showDaysHint = false});

  final GateStatus status;
  final bool showDaysHint;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final g = status.gate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CriterionRow(
          icon: Icons.track_changes_rounded,
          label: EarStrings.gateAccuracy,
          value: '%${(status.accuracy * 100).round()} / %${(g.accuracyThreshold * 100).round()}',
          fraction: status.accuracyFraction,
          met: status.accuracyMet,
        ),
        _CriterionRow(
          icon: Icons.quiz_outlined,
          label: EarStrings.gateQuestions,
          value: '${status.questions} / ${g.minQuestions}',
          fraction: status.questionsFraction,
          met: status.questionsMet,
        ),
        _CriterionRow(
          icon: Icons.calendar_month_rounded,
          label: EarStrings.gateDays,
          value: '${status.days} / ${g.minDaysActive}',
          fraction: status.daysFraction,
          met: status.daysMet,
        ),
        if (showDaysHint && !status.daysMet)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xxs),
            child: Text(
              EarStrings.gateDaysHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: p.textMuted),
            ),
          ),
      ],
    );
  }
}

final class _CriterionRow extends StatelessWidget {
  const _CriterionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.fraction,
    required this.met,
  });

  final IconData icon;
  final String label;
  final String value;
  final double fraction;
  final bool met;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final color = met ? DesignTokens.earEmerald : DesignTokens.blue500;
    return Semantics(
      label: '$label: $value${met ? ', tamam' : ''}',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(met ? Icons.check_circle_rounded : icon, size: 20, color: met ? p.success : p.textMuted),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          label,
                          style: t.bodyMedium?.copyWith(color: p.textSecondary, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        value,
                        style: t.labelLarge?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween<double>(
                        begin: AppMotion.reduced(context) ? fraction.clamp(0.0, 1.0) : 0.0,
                        end: fraction.clamp(0.0, 1.0),
                      ),
                      duration: AppMotion.dur(context, const Duration(milliseconds: 650)),
                      curve: Curves.easeOutCubic,
                      builder: (context, animValue, _) => LinearProgressIndicator(
                        value: animValue,
                        minHeight: 6,
                        backgroundColor: p.track,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
