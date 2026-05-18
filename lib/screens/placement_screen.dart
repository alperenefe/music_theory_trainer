import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
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
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/staff_interactive_field.dart';
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
      _history = h;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(AppStrings.selectSlotFirst)));
      return;
    }
    final got = NotationPitch.midiAtSlot(_slot!);
    final ok = got != null && got == _target.midi;
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
      _history = h;
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
                              AppStrings.placementTitle,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            SectionHeader(
                              title: AppStrings.targetLabel,
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
                            const SizedBox(height: AppSpacing.md),
                            Expanded(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                child: SoftCard(
                                  padding: AppSpacing.cardPad,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        AppStrings.tapStaff,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: DesignTokens.slate400,
                                            ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      SizedBox(
                                        height: AppSpacing.staffAreaHeight,
                                        child: AbsorbPointer(
                                          absorbing: _feedback,
                                          child: StaffInteractiveField(
                                            notes: _previewNotes(),
                                            highlightSlot: _slot,
                                            onSlot: (s) {
                                              if (_slot != s) {
                                                setState(() => _slot = s);
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
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
