import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theory/theory_note_labels.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/cards/soft_card.dart';

final class GoalMidiRangeCard extends StatelessWidget {
  const GoalMidiRangeCard({
    super.key,
    required this.midiChoices,
    required this.minMidi,
    required this.maxMidi,
    required this.onMinChanged,
    required this.onMaxChanged,
  });

  final List<int> midiChoices;
  final int minMidi;
  final int maxMidi;
  final ValueChanged<int> onMinChanged;
  final ValueChanged<int> onMaxChanged;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppStrings.goalRangeSection,
          style: t.titleSmall?.copyWith(
            color: DesignTokens.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppStrings.goalRangeStaffNote,
          style: t.bodySmall?.copyWith(
            color: DesignTokens.slate400,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        SoftCard(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.xxl,
          ),
          child: midiChoices.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DropdownButtonFormField<int>(
                      key: ValueKey('gmin_$minMidi'),
                      initialValue: minMidi,
                      decoration: InputDecoration(
                        labelText: AppStrings.goalMinMidi,
                        labelStyle: TextStyle(color: DesignTokens.slate400),
                      ),
                      dropdownColor: DesignTokens.slate900,
                      items: midiChoices
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                TheoryNoteLabels.label(m, withOctave: true),
                                style: const TextStyle(
                                  color: DesignTokens.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          onMinChanged(v);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<int>(
                      key: ValueKey('gmax_$maxMidi'),
                      initialValue: maxMidi,
                      decoration: InputDecoration(
                        labelText: AppStrings.goalMaxMidi,
                        labelStyle: TextStyle(color: DesignTokens.slate400),
                      ),
                      dropdownColor: DesignTokens.slate900,
                      items: midiChoices
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(
                                TheoryNoteLabels.label(m, withOctave: true),
                                style: const TextStyle(
                                  color: DesignTokens.white,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          onMaxChanged(v);
                        }
                      },
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
