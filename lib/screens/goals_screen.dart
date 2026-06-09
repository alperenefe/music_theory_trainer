import 'package:flutter/material.dart';

import '../config/goal_kind.dart';
import '../models/exercise_goal.dart';
import '../models/notation_pitch.dart';
import '../models/practice_prefs.dart';
import '../services/practice_prefs_repository.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/loading/home_list_skeleton.dart';
import '../widgets/onboarding/app_onboarding_dialog.dart';
import 'custom_workout_screen.dart';
import 'goals/goals_screen_body.dart';

final class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.repo});

  final PracticePrefsRepository repo;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

final class _GoalsScreenState extends State<GoalsScreen> {
  late Future<PracticePrefs> _load;
  late Map<String, ExerciseGoal> _goalsByKind;
  late int _minMidi;
  late int _maxMidi;
  late bool _soundEnabled;

  List<int> get _midiChoices =>
      NotationPitch.trainingPool().map((e) => e.midi).toSet().toList()..sort();

  @override
  void initState() {
    super.initState();
    _load = _read();
  }

  Future<PracticePrefs> _read() async {
    final p = await widget.repo.load();
    _goalsByKind = Map<String, ExerciseGoal>.from(p.exerciseGoals);
    for (final kind in GoalKind.practiceKinds) {
      _goalsByKind.putIfAbsent(kind, () => const ExerciseGoal());
    }
    _soundEnabled = p.soundEnabled;
    _minMidi = p.poolMinMidi;
    _maxMidi = p.poolMaxMidi;
    final mids =
        NotationPitch.trainingPool().map((e) => e.midi).toSet().toList()
          ..sort();
    if (mids.isNotEmpty) {
      if (_minMidi < mids.first) {
        _minMidi = mids.first;
      }
      if (_maxMidi > mids.last) {
        _maxMidi = mids.last;
      }
      if (!mids.contains(_minMidi)) {
        _minMidi = mids.first;
      }
      if (!mids.contains(_maxMidi)) {
        _maxMidi = mids.last;
      }
      if (_minMidi > _maxMidi) {
        _maxMidi = _minMidi;
      }
    }
    return p;
  }

  Future<void> _save() async {
    final choices = _midiChoices;
    var lo = _minMidi;
    var hi = _maxMidi;
    if (lo > hi) {
      final t = lo;
      lo = hi;
      hi = t;
    }
    if (choices.isNotEmpty) {
      if (lo < choices.first) {
        lo = choices.first;
      }
      if (hi > choices.last) {
        hi = choices.last;
      }
    }
    var pool = NotationPitch.poolForMidiRange(lo, hi);
    if (pool.isEmpty) {
      pool = NotationPitch.trainingPool();
      lo = pool.first.midi;
      hi = pool.last.midi;
    }
    final prev = await widget.repo.load();
    final savedGoals = <String, ExerciseGoal>{};
    for (final kind in GoalKind.practiceKinds) {
      final g = _goalsByKind[kind] ?? const ExerciseGoal();
      if (!g.enabled) {
        continue;
      }
      final prevG = prev.exerciseGoals[kind];
      if (prevG != null &&
          prevG.enabled &&
          prevG.target == g.target &&
          prevG.accuracyPercent == g.accuracyPercent &&
          prevG.maxAvgLatencyMs == g.maxAvgLatencyMs) {
        savedGoals[kind] = g.copyWith(
          progress: prevG.progress,
          startedAtMillis: prevG.startedAtMillis,
        );
      } else {
        final now = DateTime.now().millisecondsSinceEpoch;
        savedGoals[kind] = g.enabled && g.startedAtMillis <= 0
            ? g.copyWith(startedAtMillis: now, progress: 0)
            : g;
      }
    }
    final next = PracticePrefs(
      poolMinMidi: lo,
      poolMaxMidi: hi,
      exerciseGoals: savedGoals,
      completedGoals: prev.completedGoals,
      customWorkout: prev.customWorkout,
      soundEnabled: _soundEnabled,
      onboardingDone: prev.onboardingDone,
      referenceA4Hz: prev.referenceA4Hz,
    );
    await widget.repo.save(next);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
  }

  void _onGoalChanged(String kind, ExerciseGoal goal) {
    setState(() => _goalsByKind[kind] = goal);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: FutureBuilder<PracticePrefs>(
            future: _load,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const HomeListSkeleton();
              }
              return GoalsScreenBody(
                midiChoices: _midiChoices,
                completedGoals: snap.data!.completedGoals,
                goalsByKind: _goalsByKind,
                onGoalChanged: _onGoalChanged,
                minMidi: _minMidi,
                maxMidi: _maxMidi,
                onMinMidiChanged: (v) => setState(() => _minMidi = v),
                onMaxMidiChanged: (v) => setState(() => _maxMidi = v),
                soundEnabled: _soundEnabled,
                onSoundChanged: (v) => setState(() => _soundEnabled = v),
                onSave: _save,
                onReplayOnboarding: () => showAppOnboardingDialog(
                  context: context,
                  repo: widget.repo,
                ),
                onOpenCustomWorkout: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => CustomWorkoutScreen(repo: widget.repo),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
