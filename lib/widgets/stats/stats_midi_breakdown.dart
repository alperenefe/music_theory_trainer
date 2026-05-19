import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../services/stats_summary.dart';
import '../../utils/stats_midi_label.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

final class StatsMidiBreakdown extends StatelessWidget {
  const StatsMidiBreakdown({
    super.key,
    required this.midiStats,
    this.guitarStyleLabels = false,
  });

  final List<MidiStat> midiStats;
  final bool guitarStyleLabels;

  @override
  Widget build(BuildContext context) {
    if (midiStats.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.perMidi,
          style: t.titleSmall?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...midiStats.map(
          (m) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: RepaintBoundary(
              child: SoftCard(
                padding: AppSpacing.cardPadDense,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        StatsMidiLabel.forMidi(
                          m.midi,
                          guitarStyle: guitarStyleLabels,
                        ),
                        style: t.bodyMedium?.copyWith(
                          color: DesignTokens.white,
                        ),
                      ),
                    ),
                    Text(
                      '${(m.accuracy * 100).round()}% · '
                      '${m.correct}/${m.total} · ${m.avgMs} ms',
                      style: t.labelMedium?.copyWith(
                        color: DesignTokens.slate400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
