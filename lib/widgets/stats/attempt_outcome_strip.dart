import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';
import '../../utils/attempt_outcome_format.dart';

/// Son denemeleri D / Y zinciri olarak gösterir (kaydırılabilir).
final class AttemptOutcomeStrip extends StatelessWidget {
  const AttemptOutcomeStrip({
    super.key,
    required this.outcomes,
  });

  final List<bool> outcomes;

  @override
  Widget build(BuildContext context) {
    if (outcomes.isEmpty) {
      return const SizedBox.shrink();
    }
    return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < outcomes.length; i++) ...[
                if (i > 0) const SizedBox(width: 4),
                _OutcomeChip(correct: outcomes[i]),
              ],
            ],
          ),
        );
  }
}

final class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.correct});

  final bool correct;

  @override
  Widget build(BuildContext context) {
    final sym = outcomeSymbol(correct);
    final bg = correct
        ? DesignTokens.green400.withValues(alpha: 0.2)
        : DesignTokens.rose400.withValues(alpha: 0.2);
    final fg = correct ? DesignTokens.green400 : DesignTokens.rose400;
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.55)),
      ),
      child: Text(
        sym,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: fg,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
