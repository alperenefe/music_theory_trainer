import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/practice_history.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../services/target_picker.dart';
import '../staff/treble_staff_painter.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/staff_exercise_card.dart';
import '../widgets/text/section_header.dart';
import 'goal_completion_screen.dart';

final class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key, required this.pool});

  final List<NotationPitch> pool;

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

final class _PlacementScreenState extends State<PlacementScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  var _loading = true;
  List<PracticeAttempt> _history = [];
  late NotationPitch _target;
  int? _slot;
  var _t0 = 0;
  var _feedback = false;
  var _lastOk = false;
  String? _wrongYourAnswer;
  String? _wrongCorrectAnswer;

  @override
  void initState() {
    super.initState();
    _target = widget.pool.first;
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final h = await _repo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = PracticeHistory.forExercise(h, AppStrings.exercisePlacement);
      _loading = false;
      _newRound();
    });
  }

  void _newRound() {
    setState(() {
      _target = TargetPicker.pick(_rnd, widget.pool, _history);
      _slot = null;
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _wrongYourAnswer = null;
      _wrongCorrectAnswer = null;
    });
  }

  List<TrebleStaffNoteSpec> _previewNotes() {
    if (_slot == null) {
      return const [];
    }
    return [TrebleStaffNoteSpec(slot: _slot!)];
  }

  Future<void> _submit() async {
    if (_slot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.selectSlotFirst)),
      );
      return;
    }
    final ok = _slot == _target.staffSlot;
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;
    final attempt = PracticeAttempt(
      exercise: AppStrings.exercisePlacement,
      midi: _target.midi,
      correct: ok,
      latencyMs: ms,
      atMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.append(attempt);
    final h = await _repo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = PracticeHistory.forExercise(h, AppStrings.exercisePlacement);
      _lastOk = ok;
      _feedback = true;
      if (!ok) {
        _wrongYourAnswer = NotationPitch.displayLabelForSlot(_slot!);
        _wrongCorrectAnswer = _target.displayTurkish;
      } else {
        _wrongYourAnswer = null;
        _wrongCorrectAnswer = null;
      }
    });
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exercisePlacement,
      statsRepo: _repo,
      prefsRepo: _prefsRepo,
    );
    if (!mounted) {
      return;
    }
    if (done != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => GoalCompletionScreen(report: done),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: MeshGradientBackdrop(
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ExerciseScreenTopBar(
                      title: AppStrings.placementTitle,
                    ),
                    Expanded(
                      child: Padding(
                        padding: AppSpacing.screenHV,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionHeader(
                              title: AppStrings.placementDesc,
                              subtitle: _target.displayTurkish,
                              subtitleStyle: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    color: DesignTokens.white,
                                    fontWeight: FontWeight.w800,
                                    height: 1.2,
                                    fontSize: 30,
                                    letterSpacing: -0.5,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Expanded(
                              child: PlacementStaffCard(
                                expandToFill: true,
                                pool: widget.pool,
                                notes: _previewNotes(),
                                highlightSlot:
                                    _feedback && !_lastOk ? null : _slot,
                                wrongHighlightSlot: _feedback &&
                                        !_lastOk &&
                                        _slot != null
                                    ? _slot
                                    : null,
                                correctHighlightSlot:
                                    _feedback && !_lastOk
                                        ? _target.staffSlot
                                        : null,
                                feedback: _feedback,
                                onSlot: (s) {
                                  if (_slot != s) {
                                    setState(() => _slot = s);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            FilledButton(
                              onPressed: _feedback ? null : _submit,
                              child: Text(AppStrings.confirm),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          FeedbackBottomBar(
            show: _feedback,
            correct: _lastOk,
            onNext: _newRound,
            wrongYourAnswer: _wrongYourAnswer,
            wrongCorrectAnswer: _wrongCorrectAnswer,
          ),
        ],
      ),
    );
  }
}
