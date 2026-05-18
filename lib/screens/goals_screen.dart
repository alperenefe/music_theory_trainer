import 'package:flutter/material.dart';

import '../models/notation_pitch.dart';
import '../models/practice_prefs.dart';
import '../services/practice_prefs_repository.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import 'goals/goals_screen_body.dart';

final class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.repo});

  final PracticePrefsRepository repo;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

final class _GoalsScreenState extends State<GoalsScreen> {
  late Future<PracticePrefs> _load;
  String? _goalKind;
  late int _targetCount;
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
    _goalKind = p.goalKind;
    _soundEnabled = p.soundEnabled;
    _targetCount = p.goalTarget.clamp(10, 10000);
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
    final gk = _goalKind;
    final now = DateTime.now().millisecondsSinceEpoch;
    final prev = await widget.repo.load();
    final targetNew = _targetCount.clamp(10, 10000);
    final PracticePrefs next;
    if (gk == null) {
      next = PracticePrefs(
        poolMinMidi: lo,
        poolMaxMidi: hi,
        goalKind: null,
        goalTarget: targetNew,
        goalProgress: 0,
        goalStartedAtMillis: 0,
        soundEnabled: _soundEnabled,
        onboardingDone: prev.onboardingDone,
        referenceA4Hz: prev.referenceA4Hz,
      );
    } else {
      final reset = prev.goalKind != gk || prev.goalTarget != targetNew;
      next = PracticePrefs(
        poolMinMidi: lo,
        poolMaxMidi: hi,
        goalKind: gk,
        goalTarget: targetNew,
        goalProgress: reset ? 0 : prev.goalProgress,
        goalStartedAtMillis: reset ? now : prev.goalStartedAtMillis,
        soundEnabled: _soundEnabled,
        onboardingDone: prev.onboardingDone,
        referenceA4Hz: prev.referenceA4Hz,
      );
    }
    await widget.repo.save(next);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
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
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return GoalsScreenBody(
                midiChoices: _midiChoices,
                goalKind: _goalKind,
                onGoalKindChanged: (v) => setState(() => _goalKind = v),
                targetCount: _targetCount,
                onTargetChanged: (v) => setState(() => _targetCount = v),
                minMidi: _minMidi,
                maxMidi: _maxMidi,
                onMinMidiChanged: (v) => setState(() => _minMidi = v),
                onMaxMidiChanged: (v) => setState(() => _maxMidi = v),
                soundEnabled: _soundEnabled,
                onSoundChanged: (v) => setState(() => _soundEnabled = v),
                onSave: _save,
              );
            },
          ),
        ),
      ),
    );
  }
}
