import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import 'staff_exercise_range.dart';
import '../models/notation_pitch.dart';
import '../screens/chord_mcq_screen.dart';
import '../screens/fret_mcq_screen.dart';
import '../screens/fret_placement_screen.dart';
import '../screens/fret_play_note_screen.dart';
import '../screens/goals_screen.dart';
import '../screens/guitar_tuner_screen.dart';
import '../screens/interval_mcq_screen.dart';
import '../screens/mcq_screen.dart';
import '../screens/placement_screen.dart';
import '../screens/scale_sequence_screen.dart';
import 'exercise_route.dart';
import 'goal_kind.dart';
import '../services/practice_prefs_repository.dart';
import '../theme/design_tokens.dart';

final class HomeNavDeps {
  const HomeNavDeps({
    required this.pool,
    required this.prefsRepo,
    required this.poolMinMidi,
    required this.poolMaxMidi,
  });

  final List<NotationPitch> pool;
  final PracticePrefsRepository prefsRepo;
  final int poolMinMidi;
  final int poolMaxMidi;
}

typedef HomePageBuilder = Widget Function(HomeNavDeps d);

final class HomeRouteSpec {
  const HomeRouteSpec({
    required this.index,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    this.showStartLink = true,
    this.goalKind,
    required this.pageBuilder,
  });

  final int index;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final bool showStartLink;
  final String? goalKind;
  final HomePageBuilder pageBuilder;
}

/// Sıra: porte → teori → gitar (akort ana sayfa twin CTA ile).
final List<HomeRouteSpec> homeRouteSpecs = [
  HomeRouteSpec(
    index: 0,
    icon: Icons.touch_app_rounded,
    title: AppStrings.placementTitle,
    subtitle: AppStrings.placementDesc,
    accent: DesignTokens.blue500,
    goalKind: GoalKind.placement,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.placementTitle,
      description: AppStrings.placementDesc,
      exerciseId: AppStrings.exercisePlacement,
      goalKind: GoalKind.placement,
      buildPractice: (_) => PlacementScreen(
        pool: NotationPitch.poolForMidiRange(
          StaffExerciseRange.minMidi,
          StaffExerciseRange.maxMidi,
        ),
      ),
    ),
  ),
  HomeRouteSpec(
    index: 1,
    icon: Icons.quiz_rounded,
    title: AppStrings.mcqTitle,
    subtitle: AppStrings.mcqDesc,
    accent: DesignTokens.violet400,
    goalKind: GoalKind.mcq,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.mcqTitle,
      description: AppStrings.mcqDesc,
      exerciseId: AppStrings.exerciseMcq,
      goalKind: GoalKind.mcq,
      buildPractice: (_) => McqScreen(
        pool: NotationPitch.poolForMidiRange(
          StaffExerciseRange.minMidi,
          StaffExerciseRange.maxMidi,
        ),
      ),
    ),
  ),
  HomeRouteSpec(
    index: 2,
    icon: Icons.linear_scale_rounded,
    title: AppStrings.intervalTitle,
    subtitle: AppStrings.intervalDesc,
    accent: const Color(0xFF818CF8),
    goalKind: GoalKind.interval,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.intervalTitle,
      description: AppStrings.intervalDesc,
      exerciseId: AppStrings.exerciseInterval,
      goalKind: GoalKind.interval,
      buildPractice: (deps) => IntervalMcqScreen(
        poolMinMidi: deps.poolMinMidi,
        poolMaxMidi: deps.poolMaxMidi,
      ),
    ),
  ),
  HomeRouteSpec(
    index: 3,
    icon: Icons.grain_rounded,
    title: AppStrings.scaleTitle,
    subtitle: AppStrings.scaleDesc,
    accent: const Color(0xFFA78BFA),
    goalKind: GoalKind.scale,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.scaleTitle,
      description: AppStrings.scaleDesc,
      exerciseId: AppStrings.exerciseScale,
      goalKind: GoalKind.scale,
      buildPractice: (deps) => ScaleSequenceScreen(
        poolMinMidi: deps.poolMinMidi,
        poolMaxMidi: deps.poolMaxMidi,
      ),
    ),
  ),
  HomeRouteSpec(
    index: 4,
    icon: Icons.layers_rounded,
    title: AppStrings.chordTitle,
    subtitle: AppStrings.chordDesc,
    accent: const Color(0xFFF472B6),
    goalKind: GoalKind.chord,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.chordTitle,
      description: AppStrings.chordDesc,
      exerciseId: AppStrings.exerciseChord,
      goalKind: GoalKind.chord,
      buildPractice: (deps) => ChordMcqScreen(
        poolMinMidi: deps.poolMinMidi,
        poolMaxMidi: deps.poolMaxMidi,
      ),
    ),
  ),
  HomeRouteSpec(
    index: 5,
    icon: Icons.music_note_rounded,
    title: AppStrings.guitarMcqTitle,
    subtitle: AppStrings.guitarMcqDesc,
    accent: DesignTokens.rose400,
    goalKind: GoalKind.guitarMcq,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.guitarMcqTitle,
      description: AppStrings.guitarMcqDesc,
      exerciseId: AppStrings.exerciseGuitarMcq,
      goalKind: GoalKind.guitarMcq,
      buildPractice: (deps) => FretMcqScreen(
        poolMinMidi: deps.poolMinMidi,
        poolMaxMidi: deps.poolMaxMidi,
      ),
    ),
  ),
  HomeRouteSpec(
    index: 6,
    icon: Icons.piano_rounded,
    title: AppStrings.guitarFindTitle,
    subtitle: AppStrings.guitarFindDesc,
    accent: const Color(0xFFFC9A3A),
    goalKind: GoalKind.guitarFind,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.guitarFindTitle,
      description: AppStrings.guitarFindDesc,
      exerciseId: AppStrings.exerciseGuitarFind,
      goalKind: GoalKind.guitarFind,
      buildPractice: (deps) => FretPlacementScreen(
        poolMinMidi: deps.poolMinMidi,
        poolMaxMidi: deps.poolMaxMidi,
      ),
    ),
  ),
  HomeRouteSpec(
    index: 7,
    icon: Icons.mic_rounded,
    title: AppStrings.guitarPlayTitle,
    subtitle: AppStrings.guitarPlayDesc,
    accent: const Color(0xFF2DD4BF),
    goalKind: GoalKind.guitarPlay,
    pageBuilder: (d) => exerciseLanding(
      deps: d,
      title: AppStrings.guitarPlayTitle,
      description: AppStrings.guitarPlayDesc,
      exerciseId: AppStrings.exerciseGuitarPlay,
      goalKind: GoalKind.guitarPlay,
      buildPractice: (deps) => FretPlayNoteScreen(
        poolMinMidi: deps.poolMinMidi,
        poolMaxMidi: deps.poolMaxMidi,
      ),
    ),
  ),
  HomeRouteSpec(
    index: 8,
    icon: Icons.tune_rounded,
    title: AppStrings.tunerTitle,
    subtitle: AppStrings.tunerDesc,
    accent: const Color(0xFF38BDF8),
    showStartLink: false,
    pageBuilder: (_) => const GuitarTunerScreen(),
  ),
  HomeRouteSpec(
    index: 9,
    icon: Icons.flag_rounded,
    title: AppStrings.goalsTitle,
    subtitle: AppStrings.goalsDesc,
    accent: DesignTokens.violet500,
    showStartLink: false,
    pageBuilder: (d) => GoalsScreen(repo: d.prefsRepo),
  ),
];
