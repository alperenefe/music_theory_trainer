import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/completed_goal_record.dart';
import '../../models/exercise_goal.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import 'goal_midi_range_card.dart';
import '../../widgets/settings/app_update_card.dart';
import 'goal_sound_switch_card.dart';
import 'completed_goals_history_section.dart';
import 'per_activity_goals_section.dart';

final class GoalsScreenBody extends StatelessWidget {
  const GoalsScreenBody({
    super.key,
    required this.midiChoices,
    required this.goalsByKind,
    required this.onGoalChanged,
    required this.minMidi,
    required this.maxMidi,
    required this.onMinMidiChanged,
    required this.onMaxMidiChanged,
    required this.soundEnabled,
    required this.onSoundChanged,
    required this.onSave,
    required this.completedGoals,
    this.onReplayOnboarding,
    this.onOpenCustomWorkout,
  });

  final List<int> midiChoices;
  final Map<String, ExerciseGoal> goalsByKind;
  final void Function(String kind, ExerciseGoal goal) onGoalChanged;
  final int minMidi;
  final int maxMidi;
  final ValueChanged<int> onMinMidiChanged;
  final ValueChanged<int> onMaxMidiChanged;
  final bool soundEnabled;
  final ValueChanged<bool> onSoundChanged;
  final VoidCallback onSave;
  final List<CompletedGoalRecord> completedGoals;
  final VoidCallback? onReplayOnboarding;
  final VoidCallback? onOpenCustomWorkout;

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
              Text(
                AppStrings.goalsDesc,
                style: t.bodySmall?.copyWith(
                  color: DesignTokens.slate500,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                AppStrings.goalPerActivitySection,
                style: t.titleSmall?.copyWith(
                  color: DesignTokens.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PerActivityGoalsSection(
                goalsByKind: goalsByKind,
                onGoalChanged: onGoalChanged,
              ),
              const SizedBox(height: AppSpacing.sm),
              CompletedGoalsHistorySection(records: completedGoals),
              if (onOpenCustomWorkout != null) ...[
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton.icon(
                  onPressed: onOpenCustomWorkout,
                  icon: const Icon(Icons.tune_rounded),
                  label: Text(AppStrings.customWorkoutTitle),
                ),
              ],
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
              const SizedBox(height: AppSpacing.lg),
              const AppUpdateCard(),
              if (onReplayOnboarding != null) ...[
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: onReplayOnboarding,
                  child: Text(AppStrings.replayOnboarding),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(onPressed: onSave, child: Text(AppStrings.goalSave)),
            ],
          ),
        ),
      ],
    );
  }
}
