import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/goal_completion_report.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/practice_history.dart';
import '../services/practice_prefs_repository.dart';
import '../services/practice_session_tracker.dart';
import '../services/srs_service.dart';
import '../services/staff_curriculum_service.dart';
import '../services/stats_repository.dart';
import '../services/target_picker.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/mcq_choice_list.dart';
import '../widgets/exercise/staff_exercise_card.dart';
import '../widgets/loading/exercise_loading_body.dart';
import 'goal_completion_screen.dart';
import 'phase_unlock_screen.dart';

/// Landmark staff slotları: Sol(2), Do(-2), Fa(8)
const _mcqLandmarkSlots = [2, -2, 8];

final class McqScreen extends StatefulWidget {
  const McqScreen({super.key, this.pool});

  /// Özel antrenman için açık pool — null ise müfredat modu aktif.
  final List<NotationPitch>? pool;

  bool get _useCurriculum => pool == null;

  @override
  State<McqScreen> createState() => _McqScreenState();
}

final class _McqScreenState extends State<McqScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _srsService = SrsService();
  final _session = PracticeSessionTracker();

  var _loading = true;
  var _phase = 1;
  List<NotationPitch> _pool = const [];
  List<PracticeAttempt> _history = [];
  Set<int> _dueMidis = {};

  late NotationPitch _target;
  late List<String> _opts;
  var _t0 = 0;

  var _feedback = false;
  var _lastOk = false;
  String? _picked;
  String? _wrongYourAnswer;
  String? _wrongCorrectAnswer;

  /// Geri bildirim sırasında ekranda dondurulan tur — persist pool güncellese bile kaybolmaz.
  NotationPitch? _frozenTarget;
  List<String>? _frozenOpts;
  List<NotationPitch>? _frozenPool;

  var _advancing = false;
  int? _autoNextToken;
  Future<void>? _persistFuture;
  var _pendingPhaseUnlock = false;
  var _pendingNewPhase = 1;
  GoalCompletionReport? _pendingGoalReport;

  static const _correctHold = Duration(milliseconds: 1400);

  @override
  void initState() {
    super.initState();
    _target = NotationPitch.trainingPool().first;
    _opts = const [];
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final results = await Future.wait<Object>([
      _repo.load(),
      _prefsRepo.load(),
      _srsService.dueToday(),
    ]);
    if (!mounted) return;
    final allAttempts = results[0] as List<PracticeAttempt>;
    final prefs = results[1] as dynamic;
    final due = results[2] as List<int>;

    setState(() {
      if (widget._useCurriculum) {
        _phase = (prefs.curriculumPhase as int).clamp(
          StaffCurriculumService.minPhase,
          StaffCurriculumService.maxPhase,
        );
        _pool = StaffCurriculumService.activePool(_phase);
      } else {
        _pool = List<NotationPitch>.from(widget.pool!);
      }
      _history = PracticeHistory.forExercise(allAttempts, AppStrings.exerciseMcq);
      _dueMidis = due.toSet();
      _loading = false;
      _newRound();
    });
  }

  List<String> _buildOptions(NotationPitch target, List<NotationPitch> pool) {
    final targetSlot = target.staffSlot;
    final neighborSlots = {
      targetSlot - 2, targetSlot - 1, targetSlot + 1, targetSlot + 2,
    };

    final neighbors = pool
        .where(
          (p) => neighborSlots.contains(p.staffSlot) && p.midi != target.midi,
        )
        .toList()
      ..shuffle(_rnd);

    final wrong = <String>[];
    for (final n in neighbors) {
      if (wrong.length >= 3) break;
      if (!wrong.contains(n.displayTurkish)) wrong.add(n.displayTurkish);
    }

    final rest = pool
        .where(
          (p) => p.midi != target.midi && !wrong.contains(p.displayTurkish),
        )
        .toList()
      ..shuffle(_rnd);

    final maxWrong = min(3, pool.length - 1);
    for (final p in rest) {
      if (wrong.length >= maxWrong) break;
      wrong.add(p.displayTurkish);
    }

    return [target.displayTurkish, ...wrong]..shuffle(_rnd);
  }

  void _newRound() {
    if (_pool.isEmpty) return;
    final dueInPool = _pool.where((n) => _dueMidis.contains(n.midi)).toList();
    final nextTarget = dueInPool.isNotEmpty
        ? dueInPool[_rnd.nextInt(dueInPool.length)]
        : TargetPicker.pick(_rnd, _pool, _history);

    setState(() {
      _target = nextTarget;
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _lastOk = false;
      _picked = null;
      _wrongYourAnswer = null;
      _wrongCorrectAnswer = null;
      _frozenTarget = null;
      _frozenOpts = null;
      _frozenPool = null;
      _opts = _buildOptions(_target, _pool);
    });
  }

  void _beginFeedback(String label, bool ok) {
    setState(() {
      _frozenTarget = _target;
      _frozenOpts = List<String>.from(_opts);
      _frozenPool = List<NotationPitch>.from(_pool);
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
    _session.record(ok);
  }

  void _scheduleAutoAdvance() {
    final token = DateTime.now().microsecondsSinceEpoch;
    _autoNextToken = token;
    Future<void>.delayed(_correctHold, () {
      if (!mounted ||
          _autoNextToken != token ||
          !_feedback ||
          !_lastOk ||
          _advancing) {
        return;
      }
      unawaited(_advanceRound());
    });
  }

  Future<void> _advanceRound() async {
    if (_advancing || !_feedback) return;
    _advancing = true;
    _autoNextToken = null;
    try {
      await (_persistFuture ?? Future<void>.value());
      if (!mounted) return;

      if (_pendingPhaseUnlock) {
        final phase = _pendingNewPhase;
        _pendingPhaseUnlock = false;
        await PhaseUnlockScreen.show(context, phase);
      }
      if (!mounted) return;

      final goal = _pendingGoalReport;
      _pendingGoalReport = null;
      if (goal != null) {
        await Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            fullscreenDialog: true,
            builder: (_) => GoalCompletionScreen(report: goal),
          ),
        );
      }
      if (!mounted) return;
      _newRound();
    } finally {
      _advancing = false;
    }
  }

  Future<void> _pick(String label) async {
    if (_feedback || _advancing) return;
    final ok = label == _target.displayTurkish;
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;

    if (ok) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    _beginFeedback(label, ok);
    if (ok) {
      _scheduleAutoAdvance();
    }

    _persistFuture = _persistAnswer(ok, ms);
    await _persistFuture;
  }

  Future<void> _persistAnswer(bool ok, int ms) async {
    final answeredTarget = _frozenTarget ?? _target;

    await _repo.append(
      PracticeAttempt(
        exercise: AppStrings.exerciseMcq,
        midi: answeredTarget.midi,
        correct: ok,
        latencyMs: ms,
        atMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    await _srsService.recordAttempt(
      midi: answeredTarget.midi,
      correct: ok,
      latencyMs: ms,
    );

    final results = await Future.wait<Object>([
      _repo.load(),
      _srsService.dueToday(),
    ]);
    if (!mounted) return;

    final allAttempts = results[0] as List<PracticeAttempt>;
    final due = results[1] as List<int>;
    final staffHistory = StaffCurriculumService.staffAttempts(allAttempts);

    _history = PracticeHistory.forExercise(allAttempts, AppStrings.exerciseMcq);
    _dueMidis = due.toSet();

    var phaseAdvanced = false;
    var newPhase = _phase;
    if (widget._useCurriculum &&
        StaffCurriculumService.canAdvancePhase(_phase, staffHistory)) {
      newPhase = _phase + 1;
      final prefs = await _prefsRepo.load();
      await _prefsRepo.save(prefs.copyWith(curriculumPhase: newPhase));
      phaseAdvanced = true;
      _phase = newPhase;
      _pool = StaffCurriculumService.activePool(newPhase);
    }

    _pendingPhaseUnlock = phaseAdvanced;
    _pendingNewPhase = newPhase;
    _pendingGoalReport = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseMcq,
      statsRepo: _repo,
      prefsRepo: _prefsRepo,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const ExerciseLoadingBody();

    final showTarget = _feedback ? _frozenTarget! : _target;
    final showOpts = _feedback ? _frozenOpts! : _opts;
    final showPool = _feedback ? _frozenPool! : _pool;
    final correctLabel = showTarget.displayTurkish;

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
                      modeLabel: widget._useCurriculum
                          ? '${AppStrings.practiceModeMcq} · ${AppStrings.phaseCurrent(_phase)}'
                          : AppStrings.practiceModeMcq,
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
                                pool: showPool,
                                targetStaffSlot: showTarget.staffSlot,
                                correctHighlightSlot:
                                    _feedback ? showTarget.staffSlot : null,
                                landmarkSlots: widget._useCurriculum
                                    ? _mcqLandmarkSlots
                                        .where(
                                          (s) => showPool.any(
                                            (n) => n.staffSlot == s,
                                          ),
                                        )
                                        .toList()
                                    : const [],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              McqChoiceList(
                                options: showOpts,
                                correctLabel: correctLabel,
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
            onNext: _advanceRound,
            wrongYourAnswer: _wrongYourAnswer,
            wrongCorrectAnswer: _wrongCorrectAnswer,
            style: _lastOk
                ? FeedbackBottomBarStyle.standard
                : FeedbackBottomBarStyle.inlineCompact,
            showNextButton: !_lastOk,
          ),
        ],
      ),
    );
  }
}
