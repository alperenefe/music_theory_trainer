import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/practice_history.dart';
import '../services/practice_prefs_repository.dart';
import '../services/practice_session_tracker.dart';
import '../services/stats_repository.dart';
import '../services/target_picker.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/mcq_choice_list.dart';
import '../widgets/exercise/staff_exercise_card.dart';
import 'goal_completion_screen.dart';

final class McqScreen extends StatefulWidget {
  const McqScreen({super.key, required this.pool});

  final List<NotationPitch> pool;

  @override
  State<McqScreen> createState() => _McqScreenState();
}

final class _McqScreenState extends State<McqScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _session = PracticeSessionTracker();
  var _loading = true;
  List<PracticeAttempt> _history = [];
  late NotationPitch _target;
  late List<String> _opts;
  var _t0 = 0;
  var _feedback = false;
  var _lastOk = false;
  String? _picked;
  String? _wrongYourAnswer;
  String? _wrongCorrectAnswer;
  @override
  void initState() {
    super.initState();
    _target = widget.pool.first;
    _opts = [_target.displayTurkish];
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final h = await _repo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = PracticeHistory.forExercise(h, AppStrings.exerciseMcq);
      _loading = false;
      _newRound();
    });
  }

  void _newRound() {
    setState(() {
      _target = TargetPicker.pick(_rnd, widget.pool, _history);
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _picked = null;
      _lastOk = false;
      _wrongYourAnswer = null;
      _wrongCorrectAnswer = null;
      final maxWrong = min(3, max(0, widget.pool.length - 1));
      final wrong = <String>{};
      while (wrong.length < maxWrong) {
        final w = widget.pool[_rnd.nextInt(widget.pool.length)];
        if (w.displayTurkish != _target.displayTurkish) {
          wrong.add(w.displayTurkish);
        }
      }
      _opts = [_target.displayTurkish, ...wrong]..shuffle(_rnd);
    });
  }

  Future<void> _pick(String label) async {
    if (_feedback) {
      return;
    }
    final ok = label == _target.displayTurkish;
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;
    final attempt = PracticeAttempt(
      exercise: AppStrings.exerciseMcq,
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
    _session.record(ok);
    if (!mounted) {
      return;
    }
    setState(() {
      _history = PracticeHistory.forExercise(h, AppStrings.exerciseMcq);
      _picked = label;
      _lastOk = ok;
      _feedback = true;
      if (!ok) {
        _wrongYourAnswer = label;
        _wrongCorrectAnswer = _target.displayTurkish;
      } else {
        _wrongYourAnswer = null;
        _wrongCorrectAnswer = null;
      }
    });
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseMcq,
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
                    ExerciseScreenTopBar(
                      title: AppStrings.mcqTitle,
                      modeLabel: AppStrings.practiceModeMcq,
                      sessionCorrect: _session.correct,
                      sessionTotal: _session.total,
                    ),
                    Expanded(
                      child: Padding(
                        padding: AppSpacing.screenHV,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                AppStrings.mcqDesc,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: DesignTokens.slate400,
                                      height: 1.4,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              McqStaffCard(
                                pool: widget.pool,
                                targetStaffSlot: _target.staffSlot,
                                correctHighlightSlot: _feedback && !_lastOk
                                    ? _target.staffSlot
                                    : null,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              McqChoiceList(
                                options: _opts,
                                correctLabel: _target.displayTurkish,
                                feedback: _feedback,
                                picked: _picked,
                                onPick: _pick,
                              ),
                              SizedBox(
                                height: _feedback ? AppSpacing.xl : 0,
                              ),
                            ],
                          ),
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
            style: FeedbackBottomBarStyle.inlineCompact,
          ),
        ],
      ),
    );
  }
}
