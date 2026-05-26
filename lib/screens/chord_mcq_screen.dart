import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../services/practice_session_tracker.dart';
import '../services/stats_repository.dart';
import '../theory/music_chord.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/exercise/mcq_choice_list.dart';
import '../widgets/text/section_header.dart';
import 'goal_completion_screen.dart';

enum _ChordQMode { nameFromNotes, notesFromName }

final class ChordMcqScreen extends StatefulWidget {
  const ChordMcqScreen({
    super.key,
    required this.poolMinMidi,
    required this.poolMaxMidi,
  });

  final int poolMinMidi;
  final int poolMaxMidi;

  @override
  State<ChordMcqScreen> createState() => _ChordMcqScreenState();
}

final class _ChordMcqScreenState extends State<ChordMcqScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  final _session = PracticeSessionTracker();

  late _ChordQMode _mode;
  late int _rootMidi;
  late ChordQuality _quality;
  late List<int> _notes;
  late String _prompt;
  late List<String> _opts;
  late String _correctLabel;
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
    _rootMidi = widget.poolMinMidi +
        _rnd.nextInt(max(1, widget.poolMaxMidi - widget.poolMinMidi + 1));
    _quality = _rnd.nextBool() ? ChordQuality.major : ChordQuality.minor;
    _notes = MusicChord.triad(_rootMidi, _quality);
    _mode = _rnd.nextBool()
        ? _ChordQMode.notesFromName
        : _ChordQMode.nameFromNotes;
    if (_mode == _ChordQMode.notesFromName) {
      _prompt = MusicChord.buildNotesQuestion(_rootMidi, _quality);
      _correctLabel = MusicChord.notesJoined(_notes);
      _opts = MusicChord.buildNoteSetOptions(
        correct: _notes,
        minMidi: widget.poolMinMidi,
        maxMidi: widget.poolMaxMidi,
        rnd: _rnd,
      );
    } else {
      _correctLabel = MusicChord.chordSymbol(_rootMidi, _quality);
      _prompt = MusicChord.buildNameQuestion(_notes);
      _opts = MusicChord.buildNameOptions(
        correct: _correctLabel,
        rootMidi: _rootMidi,
        rnd: _rnd,
      );
    }
    setState(() {
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
    final ok = label == _correctLabel;
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;
    await _repo.append(
      PracticeAttempt(
        exercise: AppStrings.exerciseChord,
        midi: _rootMidi,
        correct: ok,
        latencyMs: ms,
        atMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!mounted) {
      return;
    }
    _session.record(ok);
    setState(() {
      _picked = label;
      _feedback = true;
      _lastOk = ok;
      if (!ok) {
        _wrongYour = label;
        _wrongCorrect = _correctLabel;
      }
    });
    if (ok) {
      for (final m in _notes) {
        await _audio.playMidi(m);
      }
    }
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseChord,
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
                    ExerciseScreenTopBar(
                      title: AppStrings.chordTitle,
                      modeLabel: AppStrings.practiceModeChord,
                      sessionCorrect: _session.correct,
                      sessionTotal: _session.total,
                    ),
                    Expanded(
                      child: ListView(
                        padding: AppSpacing.screenHV,
                        children: [
                          Text(
                            AppStrings.chordDesc,
                            style: t.bodyMedium?.copyWith(
                              color: DesignTokens.slate400,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SectionHeader(
                            title: AppStrings.questionLabel,
                            subtitle: _prompt,
                            subtitleStyle: t.titleMedium?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          McqChoiceList(
                            options: _opts,
                            correctLabel: _correctLabel,
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
            style: FeedbackBottomBarStyle.inlineCompact,
          ),
        ],
      ),
    );
  }
}
