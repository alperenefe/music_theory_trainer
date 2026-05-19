import 'dart:math';

import 'package:flutter/material.dart';

import '../guitar/fretboard_painter.dart';
import '../guitar/fretboard_widget.dart';
import '../l10n/app_strings.dart';
import '../models/guitar_note.dart';
import '../models/practice_prefs.dart';
import '../utils/guitar_note_pool.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/guitar/guitar_range_empty_body.dart';
import '../widgets/text/section_header.dart';
import 'goal_completion_screen.dart';

final class FretMcqScreen extends StatefulWidget {
  const FretMcqScreen({
    super.key,
    this.poolMinMidi = PracticePrefs.defaultPoolMinMidi,
    this.poolMaxMidi = PracticePrefs.defaultPoolMaxMidi,
  });

  final int poolMinMidi;
  final int poolMaxMidi;

  @override
  State<FretMcqScreen> createState() => _FretMcqScreenState();
}

final class _FretMcqScreenState extends State<FretMcqScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  late final List<GuitarNote> _allNotes = GuitarNotePool.forMidiRange(
    minMidi: widget.poolMinMidi,
    maxMidi: widget.poolMaxMidi,
  );

  late GuitarNote _target;
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
    _newRound();
  }

  void _newRound() {
    if (_allNotes.isEmpty) {
      return;
    }
    setState(() {
      _target = _allNotes[_rnd.nextInt(_allNotes.length)];
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _picked = null;
      _lastOk = false;
      _wrongYourAnswer = null;
      _wrongCorrectAnswer = null;
      _opts = GuitarNote.mcqOptionsForMidi(_target.midi, _allNotes, _rnd);
    });
    _audio.playMidi(_target.midi);
  }

  Map<GuitarNote, FretboardCellState> _buildCellStates() {
    if (!_feedback) {
      return {_target: const FretboardCellState(highlighted: true)};
    }
    return {_target: const FretboardCellState(correct: true)};
  }

  Future<void> _pick(String label) async {
    if (_feedback) return;
    final correctLabel = _target.noteName;
    final ok = label == correctLabel;
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;
    final attempt = PracticeAttempt(
      exercise: AppStrings.exerciseGuitarMcq,
      midi: _target.midi,
      correct: ok,
      latencyMs: ms,
      atMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.append(attempt);
    if (!mounted) return;
    setState(() {
      _picked = label;
      _lastOk = ok;
      _feedback = true;
      if (!ok) {
        _wrongYourAnswer = label;
        _wrongCorrectAnswer = correctLabel;
      }
    });
    if (ok) {
      _audio.playMidi(_target.midi);
    }
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseGuitarMcq,
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

  @override
  Widget build(BuildContext context) {
    if (_allNotes.isEmpty) {
      return const Scaffold(
        body: GuitarRangeEmptyBody(),
      );
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
                              AppStrings.guitarMcqTitle,
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
                      child: ListView(
                        padding: AppSpacing.screenHV,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          SectionHeader(
                            title: AppStrings.guitarMcqTitle,
                            subtitle: AppStrings.guitarMcqDesc,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SoftCard(
                            padding: AppSpacing.cardPad,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _target.positionLabel,
                                        style: t.titleMedium?.copyWith(
                                          color: DesignTokens.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () =>
                                          _audio.playMidi(_target.midi),
                                      icon: const Icon(Icons.volume_up_rounded),
                                      color: DesignTokens.slate300,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FretboardWidget(
                                  cellStates: _buildCellStates(),
                                  onCellTap: (_) =>
                                      _audio.playMidi(_target.midi),
                                  height: 190,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ..._opts.map((o) {
                            final picked = _picked == o;
                            final correctLabel = _target.noteName;
                            final showOk = _feedback && o == correctLabel;
                            final showBad =
                                _feedback && picked && o != correctLabel;
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
                              bg = DesignTokens.rose400.withValues(alpha: 0.12);
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
                                  onTap: _feedback ? null : () => _pick(o),
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
                                      style: t.titleLarge?.copyWith(
                                        color: DesignTokens.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
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
            onNext: _newRound,
            wrongYourAnswer: _wrongYourAnswer,
            wrongCorrectAnswer: _wrongCorrectAnswer,
          ),
        ],
      ),
    );
  }
}
