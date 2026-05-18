import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
import '../models/practice_prefs.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../services/target_picker.dart';
import '../staff/treble_staff_painter.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/exercise/exercise_prefs_banner.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/staff_interactive_field.dart';
import '../widgets/text/section_header.dart';
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
  PracticePrefs _prefs = const PracticePrefs();

  @override
  void initState() {
    super.initState();
    _target = widget.pool.first;
    _opts = [_target.displayTurkish];
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final h = await _repo.load();
    final p = await _prefsRepo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = h;
      _prefs = p;
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
    setState(() {
      _history = h;
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
    final pr = await _prefsRepo.load();
    if (!mounted) {
      return;
    }
    setState(() => _prefs = pr);
    if (done != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => GoalCompletionScreen(report: done),
        ),
      );
      if (mounted) {
        final pr2 = await _prefsRepo.load();
        if (mounted) {
          setState(() => _prefs = pr2);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final t = Theme.of(context).textTheme;
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
                              AppStrings.mcqTitle,
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
                      child: Padding(
                        padding: AppSpacing.screenHV,
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ExercisePrefsBanner(
                                prefs: _prefs,
                                exercise: AppStrings.exerciseMcq,
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              SectionHeader(
                                title: AppStrings.mcqTitle,
                                subtitle: AppStrings.mcqDesc,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              SoftCard(
                                padding: AppSpacing.cardPad,
                                child: SizedBox(
                                  height: AppSpacing.mcqStaffAreaHeight,
                                  child: StaffInteractiveField(
                                    readOnly: true,
                                    notes: [
                                      TrebleStaffNoteSpec(
                                        slot: _target.staffSlot,
                                      ),
                                    ],
                                    onSlot: (_) {},
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ..._opts.map((o) {
                                final picked = _picked == o;
                                final showOk =
                                    _feedback && o == _target.displayTurkish;
                                final showBad = _feedback &&
                                    picked &&
                                    o != _target.displayTurkish;
                                Color border = DesignTokens.borderSubtle;
                                Color bg = DesignTokens.slate900.withValues(
                                  alpha: 0.35,
                                );
                                if (showOk) {
                                  border = DesignTokens.green400.withValues(
                                    alpha: 0.55,
                                  );
                                  bg = DesignTokens.green400.withValues(
                                    alpha: 0.12,
                                  );
                                } else if (showBad) {
                                  border = DesignTokens.rose400.withValues(
                                    alpha: 0.55,
                                  );
                                  bg = DesignTokens.rose400.withValues(
                                    alpha: 0.12,
                                  );
                                } else if (picked && !_feedback) {
                                  border = DesignTokens.blue500;
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.md,
                                      ),
                                      onTap: _feedback
                                          ? null
                                          : () => _pick(o),
                                      child: Ink(
                                        padding: AppSpacing.cardPadDense,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            AppRadii.md,
                                          ),
                                          color: bg,
                                          border: Border.all(color: border),
                                        ),
                                        child: Text(
                                          o,
                                          style: t.titleMedium?.copyWith(
                                            color: DesignTokens.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 19,
                                            height: 1.3,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                              SizedBox(height: _feedback ? AppSpacing.xl : 0),
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
          ),
        ],
      ),
    );
  }
}
