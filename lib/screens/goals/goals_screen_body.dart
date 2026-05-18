import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/text/section_header.dart';
import 'goal_kind_chips.dart';
import 'goal_midi_range_card.dart';
import 'goal_sound_switch_card.dart';
import 'goal_target_slider_card.dart';

final class GoalsScreenBody extends StatelessWidget {
  const GoalsScreenBody({
    super.key,
    required this.midiChoices,
    required this.goalKind,
    required this.onGoalKindChanged,
    required this.targetCount,
    required this.onTargetChanged,
    required this.minMidi,
    required this.maxMidi,
    required this.onMinMidiChanged,
    required this.onMaxMidiChanged,
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.onSave,
  });

  final List<int> midiChoices;
  final String? goalKind;
  final ValueChanged<String?> onGoalKindChanged;
  final int targetCount;
  final ValueChanged<int> onTargetChanged;
  final int minMidi;
  final int maxMidi;
  final ValueChanged<int> onMinMidiChanged;
  final ValueChanged<int> onMaxMidiChanged;
  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppSpacing.screenH.copyWith(top: AppSpacing.sm),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded),
                color: DesignTokens.slate200,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  AppStrings.goalsTitle,
                  style: t.titleLarge?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: AppSpacing.screenHV,
            physics: const BouncingScrollPhysics(),
            children: [
              SectionHeader(
                title: AppStrings.goalsTitle,
                subtitle: AppStrings.goalsDesc,
              ),
              const SizedBox(height: AppSpacing.md),
              GoalKindChips(goalKind: goalKind, onChanged: onGoalKindChanged),
              const SizedBox(height: AppSpacing.lg),
              GoalTargetSliderCard(
                targetCount: targetCount,
                onChanged: onTargetChanged,
              ),
              const SizedBox(height: AppSpacing.lg),
              GoalMidiRangeCard(
                midiChoices: midiChoices,
                minMidi: minMidi,
                maxMidi: maxMidi,
                onMinChanged: onMinMidiChanged,
                onMaxChanged: onMaxMidiChanged,
              ),
              const SizedBox(height: AppSpacing.lg),
              GoalSoundSwitchCard(
                soundEnabled: soundEnabled,
                onChanged: onSoundChanged,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: onSave, child: Text(AppStrings.goalSave)),
            ],
          ),
        ),
      ],
    );
  }
}
