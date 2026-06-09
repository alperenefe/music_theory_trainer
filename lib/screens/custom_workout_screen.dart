import 'package:flutter/material.dart';

import '../config/goal_kind.dart';
import '../l10n/app_strings.dart';
import '../models/custom_workout.dart';
import '../models/notation_pitch.dart';
import '../models/practice_prefs.dart';
import '../services/custom_workout_launcher.dart';
import '../services/practice_prefs_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../theory/music_interval.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import 'goals/goal_midi_range_card.dart';

final class CustomWorkoutScreen extends StatefulWidget {
  const CustomWorkoutScreen({super.key, required this.repo});

  final PracticePrefsRepository repo;

  @override
  State<CustomWorkoutScreen> createState() => _CustomWorkoutScreenState();
}

final class _CustomWorkoutScreenState extends State<CustomWorkoutScreen> {
  late String _exerciseKind;
  late int _minMidi;
  late int _maxMidi;
  late Set<String> _intervalKindNames;
  var _loading = true;

  List<int> get _midiChoices =>
      NotationPitch.trainingPool().map((e) => e.midi).toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await widget.repo.load();
    final w = prefs.customWorkout ??
        CustomWorkout.defaultsForPrefs(
          poolMinMidi: prefs.poolMinMidi,
          poolMaxMidi: prefs.poolMaxMidi,
          exerciseKind: GoalKind.mcq,
        );
    if (!mounted) {
      return;
    }
    setState(() {
      _exerciseKind = w.exerciseKind;
      _minMidi = w.minMidi;
      _maxMidi = w.maxMidi;
      _intervalKindNames = w.intervalKinds.isEmpty
          ? MusicInterval.practiceSet.map((e) => e.name).toSet()
          : w.intervalKinds.toSet();
      _loading = false;
    });
  }

  CustomWorkout _buildWorkout() {
    return CustomWorkout(
      exerciseKind: _exerciseKind,
      minMidi: _minMidi,
      maxMidi: _maxMidi,
      intervalKinds: _exerciseKind == GoalKind.interval
          ? _intervalKindNames.toList()
          : const [],
    );
  }

  Future<void> _save() async {
    final prev = await widget.repo.load();
    await widget.repo.save(prev.copyWith(customWorkout: _buildWorkout()));
  }

  Future<void> _start() async {
    await _save();
    if (!mounted) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CustomWorkoutLauncher.practiceScreen(_buildWorkout()),
      ),
    );
  }

  void _toggleIntervalKind(IntervalKind kind, bool on) {
    setState(() {
      if (on) {
        _intervalKindNames.add(kind.name);
      } else {
        _intervalKindNames.remove(kind.name);
        if (_intervalKindNames.isEmpty) {
          _intervalKindNames.add(kind.name);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
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
                          Expanded(
                            child: Text(
                              AppStrings.customWorkoutTitle,
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
                        children: [
                          Text(
                            AppStrings.customWorkoutDesc,
                            style: t.bodyMedium?.copyWith(
                              color: DesignTokens.slate400,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            AppStrings.customWorkoutExerciseSection,
                            style: t.titleSmall?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...GoalKind.practiceKinds.map((kind) {
                            final title = GoalKind.titleWithFallback(kind);
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.xs,
                              ),
                              child: RadioListTile<String>(
                                value: kind,
                                groupValue: _exerciseKind,
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _exerciseKind = v);
                                  }
                                },
                                title: Text(
                                  title,
                                  style: t.bodyLarge?.copyWith(
                                    color: DesignTokens.white,
                                  ),
                                ),
                                activeColor: DesignTokens.violet400,
                                contentPadding: EdgeInsets.zero,
                              ),
                            );
                          }),
                          const SizedBox(height: AppSpacing.lg),
                          GoalMidiRangeCard(
                            midiChoices: _midiChoices,
                            minMidi: _minMidi,
                            maxMidi: _maxMidi,
                            onMinChanged: (v) => setState(() => _minMidi = v),
                            onMaxChanged: (v) => setState(() => _maxMidi = v),
                          ),
                          if (_exerciseKind == GoalKind.interval) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              AppStrings.customWorkoutIntervalSection,
                              style: t.titleSmall?.copyWith(
                                color: DesignTokens.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                for (final kind in MusicInterval.practiceSet)
                                  FilterChip(
                                    label: Text(
                                      MusicInterval.turkishName(kind),
                                    ),
                                    selected: _intervalKindNames.contains(
                                      kind.name,
                                    ),
                                    onSelected: (on) =>
                                        _toggleIntervalKind(kind, on),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: AppSpacing.screenH.copyWith(
                        bottom: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: _start,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(AppStrings.customWorkoutStart),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          OutlinedButton(
                            onPressed: () async {
                              await _save();
                              if (mounted) {
                                Navigator.of(context).pop();
                              }
                            },
                            child: Text(AppStrings.customWorkoutSave),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
