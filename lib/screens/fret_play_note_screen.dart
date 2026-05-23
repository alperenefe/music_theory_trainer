import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';

import '../l10n/app_strings.dart';
import '../models/guitar_note.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';
import '../models/practice_prefs.dart';
import '../services/goal_tracker.dart';
import '../services/practice_history.dart';
import '../services/target_picker.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../utils/guitar_note_pool.dart';
import '../utils/guitar_target_pitch_match.dart';
import '../utils/mic_energy_gate.dart';
import '../utils/mic_pitch_session.dart';
import '../utils/microphone_pitch_smoother.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/guitar/fret_play_listening_card.dart';
import '../widgets/guitar/guitar_range_empty_body.dart';
import '../widgets/text/section_header.dart';
import 'goal_completion_screen.dart';

final class FretPlayNoteScreen extends StatefulWidget {
  const FretPlayNoteScreen({
    super.key,
    this.poolMinMidi = PracticePrefs.defaultPoolMinMidi,
    this.poolMaxMidi = PracticePrefs.defaultPoolMaxMidi,
  });

  final int poolMinMidi;
  final int poolMaxMidi;

  @override
  State<FretPlayNoteScreen> createState() => _FretPlayNoteScreenState();
}

final class _FretPlayNoteScreenState extends State<FretPlayNoteScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  final _mic = MicPitchSession();
  late List<GuitarNote> _allNotes;
  List<PracticeAttempt> _history = [];

  late GuitarNote _targetNote;
  late String _targetLabel;
  var _t0 = 0;
  var _feedback = false;
  var _lastOk = false;
  var _listening = false;
  double? _lastHz;
  String? _lastNoteName;
  double? _cents;
  final _stable = <int>[];
  static const int _stableNeed = 4;
  static const double _inTuneCents = 35;
  var _quietStreak = 0;
  final _hzSmoother = PitchReadingSmoother(
    alpha: 0.12,
    maxJumpCents: 180,
    invalidStreakToReset: 10,
  );
  var _refA4 = PracticePrefs.defaultReferenceA4Hz;

  @override
  void initState() {
    super.initState();
    _mic.attach();
    _mic.onStopped = () {
      if (mounted && _listening) {
        setState(() => _listening = false);
      } else {
        _listening = false;
      }
    };
    _allNotes = GuitarNotePool.forMidiRange(
      minMidi: widget.poolMinMidi,
      maxMidi: widget.poolMaxMidi,
    );
    _bootstrap();
    _loadPrefsRef();
  }

  Future<void> _bootstrap() async {
    final h = await _repo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = PracticeHistory.forExercise(h, AppStrings.exerciseGuitarPlay);
      _newRound();
    });
  }

  Future<void> _loadPrefsRef() async {
    final p = await _prefsRepo.load();
    if (!mounted) {
      return;
    }
    setState(() => _refA4 = p.referenceA4Hz);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryStartMic();
    });
  }

  @override
  void dispose() {
    _mic.detach();
    super.dispose();
  }

  void _assignTarget(GuitarNote note) {
    _targetNote = note;
    _targetLabel = NotationPitch.buildDisplayLabel(note.midi);
    _hzSmoother.reset();
    _stable.clear();
  }

  void _newRound() {
    _stopMic();
    if (_allNotes.isEmpty) {
      return;
    }
    setState(() {
      _assignTarget(
        TargetPicker.pickGuitarNote(_rnd, _allNotes, _history),
      );
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _lastOk = false;
      _lastHz = null;
      _lastNoteName = null;
      _cents = null;
      _quietStreak = 0;
    });
    _loadPrefsRef();
  }

  void _stopMic() {
    _mic.stop();
    _quietStreak = 0;
    _hzSmoother.reset();
    if (_listening && mounted) {
      setState(() => _listening = false);
    } else {
      _listening = false;
    }
  }

  Future<void> _showMicRationale() async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppStrings.micPermissionRationale)),
    );
  }

  Future<void> _tryStartMic() async {
    if (_feedback || _listening) {
      return;
    }
    _quietStreak = 0;
    _hzSmoother.reset();
    _stable.clear();
    final ok = await _mic.start(
      onFrame: _onPitchSample,
      onShowRationale: _showMicRationale,
      onPermissionDenied: () async {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.guitarPlayDenied)),
          );
        }
      },
    );
    if (mounted && ok) {
      setState(() => _listening = true);
    }
  }

  void _toggleMic() {
    if (_feedback) {
      return;
    }
    if (_listening) {
      _stopMic();
    } else {
      _tryStartMic();
    }
  }

  Future<void> _pickTargetNote() async {
    if (_feedback) {
      return;
    }
    final sorted = List<GuitarNote>.from(_allNotes)
      ..sort((a, b) => a.midi.compareTo(b.midi));
    final picked = await showModalBottomSheet<GuitarNote>(
      context: context,
      backgroundColor: DesignTokens.slate900,
      showDragHandle: true,
      builder: (ctx) {
        final t = Theme.of(ctx).textTheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: AppSpacing.screenH,
                child: Text(
                  AppStrings.guitarPlayPickNoteTitle,
                  style: t.titleMedium?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  itemBuilder: (context, i) {
                    final n = sorted[i];
                    final label = NotationPitch.buildDisplayLabel(n.midi);
                    final selected = n.midi == _targetNote.midi;
                    return ListTile(
                      selected: selected,
                      title: Text(
                        label,
                        style: t.titleMedium?.copyWith(
                          color: DesignTokens.white,
                          fontWeight:
                              selected ? FontWeight.w800 : FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        '${n.stringLabel} teli · ${n.fret}. perde',
                        style: t.bodySmall?.copyWith(
                          color: DesignTokens.slate400,
                        ),
                      ),
                      onTap: () => Navigator.pop(ctx, n),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
    if (!mounted || picked == null) {
      return;
    }
    setState(() {
      _assignTarget(picked);
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _lastHz = null;
      _lastNoteName = null;
      _cents = null;
      _quietStreak = 0;
    });
  }

  void _onPitchSample(PitchFrame frame) {
    if (!mounted || _feedback || !_listening) {
      return;
    }
    if (frame.rms < MicEnergyGate.fretPlayMinRms) {
      _quietStreak++;
      if (_quietStreak >= MicEnergyGate.quietFramesToClearFret) {
        setState(() {
          _lastHz = null;
          _lastNoteName = null;
          _cents = null;
        });
        _stable.clear();
      }
      return;
    }
    _quietStreak = 0;
    final hz = frame.hz;
    if (!hz.isFinite) {
      return;
    }
    final folded = GuitarTargetPitchMatch.foldToFundamental(
      hz: hz,
      targetMidi: _targetNote.midi,
      referenceA4: _refA4,
    );
    final smoothed = _hzSmoother.push(folded);
    if (smoothed == null) {
      setState(() {
        _lastHz = null;
        _lastNoteName = null;
        _cents = null;
      });
      _stable.clear();
      return;
    }
    final matched = GuitarTargetPitchMatch.matchMidi(
      hz: smoothed,
      targetMidi: _targetNote.midi,
      referenceA4: _refA4,
    );
    final cents = GuitarTargetPitchMatch.centsToTargetMidi(
      hz: smoothed,
      targetMidi: _targetNote.midi,
      referenceA4: _refA4,
    );
    if (matched == null || cents == null) {
      setState(() {
        _lastHz = null;
        _lastNoteName = null;
        _cents = null;
      });
      _stable.clear();
      return;
    }
    final name = GuitarNote.noteNameForMidi(matched);
    final onTarget =
        matched == _targetNote.midi && cents.abs() <= _inTuneCents;
    if (onTarget) {
      _stable.add(matched);
    } else {
      _stable.clear();
    }
    while (_stable.length > _stableNeed) {
      _stable.removeAt(0);
    }
    setState(() {
      _lastHz = smoothed;
      _lastNoteName = name;
      _cents = cents;
    });
    if (_stable.length == _stableNeed) {
      _completeCorrect(_targetNote.midi);
    }
  }

  Future<void> _completeCorrect(int midi) async {
    if (_feedback) {
      return;
    }
    _stopMic();
    final ms = DateTime.now().millisecondsSinceEpoch - _t0;
    final attempt = PracticeAttempt(
      exercise: AppStrings.exerciseGuitarPlay,
      midi: midi,
      correct: true,
      latencyMs: ms,
      atMillis: DateTime.now().millisecondsSinceEpoch,
    );
    await _repo.append(attempt);
    final h = await _repo.load();
    if (!mounted) {
      return;
    }
    setState(() {
      _history = PracticeHistory.forExercise(h, AppStrings.exerciseGuitarPlay);
      _lastOk = true;
      _feedback = true;
    });
    await _audio.playMidi(midi);
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseGuitarPlay,
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

  Future<void> _previewTarget() async {
    await _audio.playMidi(_targetNote.midi);
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
                              AppStrings.guitarPlayTitle,
                              style: t.titleLarge?.copyWith(
                                color: DesignTokens.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          if (_listening)
                            IconButton(
                              onPressed: _feedback ? null : _stopMic,
                              tooltip: AppStrings.guitarPlayStop,
                              icon: const Icon(Icons.mic_off_rounded),
                              color: DesignTokens.slate200,
                            )
                          else
                            IconButton(
                              onPressed: _feedback ? null : _tryStartMic,
                              tooltip: AppStrings.tunerMicResume,
                              icon: const Icon(Icons.mic_rounded),
                              color: DesignTokens.blue500,
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
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              TextButton.icon(
                                onPressed: _feedback ? null : _previewTarget,
                                icon: Icon(
                                  Icons.volume_up_rounded,
                                  color: DesignTokens.blue500,
                                ),
                                label: Text(
                                  AppStrings.guitarPlayPreview,
                                  style: t.labelLarge?.copyWith(
                                    color: DesignTokens.slate200,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton.icon(
                                onPressed:
                                    _feedback ? null : _pickTargetNote,
                                icon: Icon(
                                  Icons.piano_rounded,
                                  color: DesignTokens.blue500,
                                ),
                                label: Text(
                                  AppStrings.guitarPlayChangeTarget,
                                  style: t.labelLarge?.copyWith(
                                    color: DesignTokens.slate200,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FretPlayListeningCard(
                            textTheme: t,
                            listening: _listening,
                            feedback: _feedback,
                            lastNoteName: _lastNoteName,
                            lastHz: _lastHz,
                            cents: _cents,
                            onToggleMic: _toggleMic,
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
            onNext: _newRound,
            wrongYourAnswer: null,
            wrongCorrectAnswer: null,
          ),
        ],
      ),
    );
  }
}
