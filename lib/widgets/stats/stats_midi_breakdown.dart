import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_attempt.dart';
import '../../services/stats_summary.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../utils/attempt_outcome_format.dart';
import '../../utils/stats_midi_label.dart';
import 'accuracy_progress_bar.dart';
import 'attempt_outcome_strip.dart';

final class StatsMidiBreakdown extends StatelessWidget {
  const StatsMidiBreakdown({
    super.key,
    required this.midiStats,
    required this.attempts,
    this.guitarStyleLabels = false,
  });

  final List<MidiStat> midiStats;
  final List<PracticeAttempt> attempts;
  final bool guitarStyleLabels;

  @override
  Widget build(BuildContext context) {
    if (midiStats.isEmpty) {
      return const SizedBox.shrink();
    }
    final t = Theme.of(context).textTheme;
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        initiallyExpanded: false,
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: AppSpacing.xs),
        title: Text(
          AppStrings.perMidi,
          style: t.titleSmall?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          AppStrings.statsNoteSectionCount(midiStats.length),
          style: t.labelSmall?.copyWith(color: DesignTokens.slate500),
        ),
        children: midiStats
            .map(
              (m) => _NoteStatTile(
                stat: m,
                attempts: attempts,
                guitarStyleLabels: guitarStyleLabels,
              ),
            )
            .toList(),
      ),
    );
  }
}

final class _NoteStatTile extends StatelessWidget {
  const _NoteStatTile({
    required this.stat,
    required this.attempts,
    required this.guitarStyleLabels,
  });

  final MidiStat stat;
  final List<PracticeAttempt> attempts;
  final bool guitarStyleLabels;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final pct = (stat.accuracy * 100).round();
    final accColor =
        pct >= 80 ? DesignTokens.green400 : const Color(0xFFF97316);
    final noteOutcomes = outcomesForMidi(attempts, stat.midi);
    final last2 = noteOutcomes.length <= 2
        ? noteOutcomes
        : noteOutcomes.sublist(noteOutcomes.length - 2);
    final pickerHint =
        last2.isEmpty ? '' : ' · ${formatOutcomeChain(last2)}';

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          childrenPadding: const EdgeInsets.only(
            bottom: AppSpacing.sm,
            left: AppSpacing.sm,
            right: AppSpacing.sm,
          ),
          title: Text(
            StatsMidiLabel.forMidi(
              stat.midi,
              guitarStyle: guitarStyleLabels,
            ),
            style: t.bodyMedium?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${AppStrings.statsNoteEncounters(stat.total)}'
            ' · $pct% · ${stat.correct}/${stat.total}$pickerHint',
            style: t.labelSmall?.copyWith(
              color: accColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            AccuracyProgressBar(
              accuracy: stat.accuracy,
              height: 6,
              useGradient: false,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.statsNotePickerHint,
              style: t.labelSmall?.copyWith(color: DesignTokens.slate500),
            ),
            const SizedBox(height: AppSpacing.xs),
            AttemptOutcomeStrip(outcomes: noteOutcomes),
          ],
        ),
      ),
    );
  }
}
