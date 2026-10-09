import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
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
import '../staff/staff_slot_offset.dart';
import '../staff/treble_staff_painter.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/staff_exercise_card.dart';
import '../widgets/loading/exercise_loading_body.dart';
import 'goal_completion_screen.dart';
import 'phase_unlock_screen.dart';

const _placementLandmarkSlots = [2, -2, 8];

final class PlacementScreen extends StatefulWidget {
  const PlacementScreen({super.key, this.pool});

  /// Özel antrenman için açık pool — null ise müfredat modu aktif.
  final List<NotationPitch>? pool;

  bool get _useCurriculum => pool == null;

  @override
  State<PlacementScreen> createState() => _PlacementScreenState();
}

final class _PlacementScreenState extends State<PlacementScreen> {
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
  int? _slot;
  var _t0 = 0;
  var _feedback = false;
  var _lastOk = false;
  String? _slotOffsetHint;

  @override
  void initState() {
    super.initState();
    _target = NotationPitch.trainingPool().first;
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
      _history = PracticeHistory.forExercise(allAttempts, AppStrings.exercisePlacement);
      _dueMidis = due.toSet();
      _loading = false;
      _newRound();
    });
  }

  void _newRound() {
    if (_pool.isEmpty) return;
    setState(() {
      final dueInPool =
          _pool.where((n) => _dueMidis.contains(n.midi)).toList();
      if (dueInPool.isNotEmpty) {
        _target = dueInPool[_rnd.nextInt(dueInPool.length)];
      } else {
        _target = TargetPicker.pick(_rnd, _pool, _history);
      }
      _slot = null;
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _slotOffsetHint = null;
    });
  }

  List<TrebleStaffNoteSpec> _staffNotes() {
    if (_feedback && !_lastOk && _slot != null) {
      return [
        TrebleStaffNoteSpec(
          slot: _slot!,
          feedback: StaffNoteFeedbackKind.wrongPick,
        ),
        TrebleStaffNoteSpec(
          slot: _target.staffSlot,
          feedback: StaffNoteFeedbackKind.correctTarget,
        ),
      ];
    }
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

    await _srsService.recordAttempt(
      midi: _target.midi,
      correct: ok,
      latencyMs: ms,
    );

    final results = await Future.wait<Object>([
      _repo.load(),
      _srsService.dueToday(),
    ]);
    if (!mounted) return;
    _session.record(ok);
    if (!mounted) return;

    final allAttempts = results[0] as List<PracticeAttempt>;
    final due = results[1] as List<int>;
    final staffHistory = StaffCurriculumService.staffAttempts(allAttempts);

    var phaseAdvanced = false;
    var newPhase = _phase;
    if (widget._useCurriculum &&
        StaffCurriculumService.canAdvancePhase(_phase, staffHistory)) {
      newPhase = _phase + 1;
      final prefs = await _prefsRepo.load();
      await _prefsRepo.save(prefs.copyWith(curriculumPhase: newPhase));
      phaseAdvanced = true;
    }

    if (!mounted) return;
    setState(() {
      _history = PracticeHistory.forExercise(allAttempts, AppStrings.exercisePlacement);
      _dueMidis = due.toSet();
      if (phaseAdvanced) {
        _phase = newPhase;
        _pool = StaffCurriculumService.activePool(newPhase);
      }
      _lastOk = ok;
      _feedback = true;
      if (!ok) {
        _slotOffsetHint = StaffSlotOffset.describe(
          correctSlot: _target.staffSlot,
          userSlot: _slot!,
        );
      } else {
        _slotOffsetHint = null;
      }
    });

    if (phaseAdvanced && mounted) {
      await PhaseUnlockScreen.show(context, newPhase);
    }

    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exercisePlacement,
      statsRepo: _repo,
      prefsRepo: _prefsRepo,
    );
    if (!mounted) return;
    if (done != null) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          fullscreenDialog: true,
          builder: (_) => GoalCompletionScreen(report: done),
        ),
      );
    }
  }

  Widget _bottomActions(BuildContext context) {
    if (_feedback) {
      return FeedbackBottomBar(
        show: true,
        correct: _lastOk,
        onNext: _newRound,
        placementOffsetHint: _slotOffsetHint,
        style: FeedbackBottomBarStyle.placementCompact,
        embedded: true,
      );
    }
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.practiceActionHeight,
      child: FilledButton(
        onPressed: _submit,
        child: Text(AppStrings.confirm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ExerciseLoadingBody();
    }
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExerciseScreenTopBar(
                title: AppStrings.placementTitle,
                modeLabel: widget._useCurriculum
                    ? '${AppStrings.practiceModePlacement} · ${AppStrings.phaseCurrent(_phase)}'
                    : AppStrings.practiceModePlacement,
                sessionCorrect: _session.correct,
                sessionTotal: _session.total,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '${AppStrings.targetLabel}: ${_target.displayTurkish}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.headlineSmall?.copyWith(
                          color: DesignTokens.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 26,
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Expanded(
                        child: PlacementStaffCard(
                          expandToFill: true,
                          tapHint: AppStrings.placementTapHint,
                          pool: _pool,
                          landmarkSlots: widget._useCurriculum
                              ? _placementLandmarkSlots
                                  .where(
                                    (s) =>
                                        _pool.any((n) => n.staffSlot == s),
                                  )
                                  .toList()
                              : const [],
                          notes: _staffNotes(),
                          highlightSlot: _feedback ? null : _slot,
                          feedback: _feedback,
                          onSlot: (s) {
                            if (_feedback) {
                              return;
                            }
                            if (_slot != s) {
                              setState(() => _slot = s);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      SafeArea(
                        top: false,
                        minimum: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: _bottomActions(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
