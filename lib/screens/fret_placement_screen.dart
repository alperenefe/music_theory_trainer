import 'dart:math';

import 'package:flutter/material.dart';

import '../guitar/fretboard_painter.dart';
import '../guitar/fretboard_widget.dart';
import '../l10n/app_strings.dart';
import '../models/guitar_note.dart';
import '../theory/theory_note_labels.dart';
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

final class FretPlacementScreen extends StatefulWidget {
  const FretPlacementScreen({
    super.key,
    this.poolMinMidi = PracticePrefs.defaultPoolMinMidi,
    this.poolMaxMidi = PracticePrefs.defaultPoolMaxMidi,
  });

  final int poolMinMidi;
  final int poolMaxMidi;

  @override
  State<FretPlacementScreen> createState() => _FretPlacementScreenState();
}

final class _FretPlacementScreenState extends State<FretPlacementScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  late List<GuitarNote> _allNotes;
  late GuitarNote _targetNote;
  late int _targetPitchClass;
  late String _targetLabel;
  late List<GuitarNote> _correctCells;
  GuitarNote? _selected;
  var _t0 = 0;
  var _feedback = false;
  var _lastOk = false;
  var _revealAll = false;

  @override
  void initState() {
    super.initState();
    _allNotes = GuitarNotePool.forMidiRange(
      minMidi: widget.poolMinMidi,
      maxMidi: widget.poolMaxMidi,
    );
    _newRound();
  }

  void _newRound() {
    if (_allNotes.isEmpty) {
      return;
    }
    setState(() {
      _targetNote = _allNotes[_rnd.nextInt(_allNotes.length)];
      _targetPitchClass = _targetNote.pitchClass;
      _correctCells = _allNotes
          .where((n) => n.pitchClass == _targetPitchClass)
          .toList();
      _targetLabel = TheoryNoteLabels.label(
        _targetNote.midi,
        withOctave: true,
      );
      _selected = null;
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _lastOk = false;
      _revealAll = false;
    });
  }

  Map<GuitarNote, FretboardCellState> _buildCellStates() {
    final map = <GuitarNote, FretboardCellState>{};
    if (!_feedback) {
      if (_selected != null) {
        map[_selected!] = const FretboardCellState(selected: true);
      }
      return map;
    }
    if (_lastOk) {
      if (_selected != null) {
        map[_selected!] = const FretboardCellState(correct: true);
      }
      return map;
    }
    for (final c in _correctCells) {
      map[c] = const FretboardCellState(correct: true);
    }
    if (_selected != null) {
      map[_selected!] = const FretboardCellState(incorrect: true);
    }
    return map;
  }

  Future<void> _onCellTap(GuitarNote note) async {
    if (_feedback) {
      _audio.playMidi(note.midi);
      return;
    }
    _audio.playMidi(note.midi);
    final ok = note.pitchClass == _targetPitchClass;
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;
    final attempt = PracticeAttempt(
      exercise: AppStrings.exerciseGuitarFind,
      midi: note.midi,
      correct: ok,
      latencyMs: ms,
      atMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.append(attempt);
    if (!mounted) return;
    setState(() {
      _selected = note;
      _lastOk = ok;
      _feedback = true;
      _revealAll = !ok;
    });
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseGuitarFind,
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
                              AppStrings.guitarFindTitle,
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
                            title: AppStrings.targetLabel,
                            subtitle: _targetLabel,
                            subtitleStyle: t.displaySmall?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SoftCard(
                            padding: AppSpacing.cardPad,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  _feedback
                                      ? '${_correctCells.length} doğru perde'
                                      : AppStrings.guitarTapHint,
                                  style: t.bodySmall?.copyWith(
                                    color: DesignTokens.slate400,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                FretboardWidget(
                                  cellStates: _buildCellStates(),
                                  onCellTap: _onCellTap,
                                  height: 200,
                                ),
                              ],
                            ),
                          ),
                          if (_feedback && !_lastOk && _revealAll) ...[
                            const SizedBox(height: AppSpacing.md),
                            SoftCard(
                              padding: AppSpacing.cardPadDense,
                              child: Text(
                                AppStrings.guitarAllCorrectShown,
                                style: t.bodySmall?.copyWith(
                                  color: DesignTokens.green400,
                                ),
                              ),
                            ),
                          ],
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
            wrongYourAnswer: _lastOk
                ? null
                : _selected == null
                    ? null
                    : '${_selected!.noteName} · ${_selected!.positionLabel}',
            wrongCorrectAnswer: _lastOk ? null : _targetLabel,
          ),
        ],
      ),
    );
  }
}
