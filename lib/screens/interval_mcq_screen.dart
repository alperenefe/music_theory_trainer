import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../theory/interval_question.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/mcq_choice_list.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/text/section_header.dart';
import 'goal_completion_screen.dart';

final class IntervalMcqScreen extends StatefulWidget {
  const IntervalMcqScreen({
    super.key,
    required this.poolMinMidi,
    required this.poolMaxMidi,
  });

  final int poolMinMidi;
  final int poolMaxMidi;

  @override
  State<IntervalMcqScreen> createState() => _IntervalMcqScreenState();
}

final class _IntervalMcqScreenState extends State<IntervalMcqScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  late IntervalQuestion _q;
  var _t0 = 0;
  var _feedback = false;
  var _lastOk = false;
  String? _picked;
  String? _wrongYour;
  String? _wrongCorrect;

  @override
  void initState() {
    super.initState();
    _newQuestion();
  }

  void _newQuestion() {
    setState(() {
      _q = IntervalQuestion.random(_rnd, widget.poolMinMidi, widget.poolMaxMidi);
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _lastOk = false;
      _picked = null;
      _wrongYour = null;
      _wrongCorrect = null;
    });
  }

  Future<void> _pick(String label) async {
    if (_feedback) {
      return;
    }
    final ok = label == _q.correctLabel;
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;
    await _repo.append(
      PracticeAttempt(
        exercise: AppStrings.exerciseInterval,
        midi: _q.answerMidi,
        correct: ok,
        latencyMs: ms,
        atMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _picked = label;
      _feedback = true;
      _lastOk = ok;
      if (!ok) {
        _wrongYour = label;
        _wrongCorrect = _q.correctLabel;
      }
    });
    if (ok) {
      await _audio.playMidi(_q.answerMidi);
    }
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseInterval,
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
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: MeshGradientBackdrop(
              child: SafeArea(
                child: Column(
                  children: [
                    const ExerciseScreenTopBar(title: AppStrings.intervalTitle),
                    Expanded(
                      child: ListView(
                        padding: AppSpacing.screenHV,
                        children: [
                          Text(
                            AppStrings.intervalDesc,
                            style: t.bodyMedium?.copyWith(
                              color: DesignTokens.slate400,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SectionHeader(
                            title: AppStrings.questionLabel,
                            subtitle: _q.prompt,
                            subtitleStyle: t.titleLarge?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          McqChoiceList(
                            options: _q.options,
                            correctLabel: _q.correctLabel,
                            feedback: _feedback,
                            picked: _picked,
                            onPick: _pick,
                          ),
                        ],
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
            onNext: _newQuestion,
            wrongYourAnswer: _wrongYour,
            wrongCorrectAnswer: _wrongCorrect,
          ),
        ],
      ),
    );
  }
}
