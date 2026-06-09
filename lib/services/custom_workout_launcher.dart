import 'package:flutter/material.dart';

import '../config/goal_kind.dart';
import '../config/staff_exercise_range.dart';
import '../models/custom_workout.dart';
import '../models/notation_pitch.dart';
import '../screens/chord_mcq_screen.dart';
import '../screens/fret_mcq_screen.dart';
import '../screens/fret_placement_screen.dart';
import '../screens/fret_play_note_screen.dart';
import '../screens/interval_mcq_screen.dart';
import '../screens/mcq_screen.dart';
import '../screens/placement_screen.dart';
import '../screens/scale_sequence_screen.dart';

abstract final class CustomWorkoutLauncher {
  static Widget practiceScreen(CustomWorkout workout) {
    var lo = workout.minMidi;
    var hi = workout.maxMidi;
    if (lo > hi) {
      final t = lo;
      lo = hi;
      hi = t;
    }
    var pool = NotationPitch.poolForMidiRange(lo, hi);
    if (pool.isEmpty) {
      pool = NotationPitch.trainingPool();
      lo = pool.first.midi;
      hi = pool.last.midi;
    }

    return switch (workout.exerciseKind) {
      GoalKind.placement => PlacementScreen(pool: pool),
      GoalKind.mcq => McqScreen(pool: pool),
      GoalKind.interval => IntervalMcqScreen(
          poolMinMidi: lo,
          poolMaxMidi: hi,
          allowedIntervalKinds: workout.resolvedIntervalKinds(),
        ),
      GoalKind.scale => ScaleSequenceScreen(
          poolMinMidi: lo,
          poolMaxMidi: hi,
        ),
      GoalKind.chord => ChordMcqScreen(
          poolMinMidi: lo,
          poolMaxMidi: hi,
        ),
      GoalKind.guitarMcq => FretMcqScreen(
          poolMinMidi: lo,
          poolMaxMidi: hi,
        ),
      GoalKind.guitarFind => FretPlacementScreen(
          poolMinMidi: lo,
          poolMaxMidi: hi,
        ),
      GoalKind.guitarPlay => FretPlayNoteScreen(
          poolMinMidi: lo,
          poolMaxMidi: hi,
        ),
      _ => McqScreen(
          pool: NotationPitch.poolForMidiRange(
            StaffExerciseRange.minMidi,
            StaffExerciseRange.maxMidi,
          ),
        ),
    };
  }
}
