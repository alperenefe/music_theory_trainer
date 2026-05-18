import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_detect_pitch/flutter_detect_pitch.dart';
import 'package:permission_handler/permission_handler.dart';

import '../l10n/app_strings.dart';
import '../models/guitar_note.dart';
import '../models/practice_attempt.dart';
import '../models/practice_prefs.dart';
import '../services/goal_tracker.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../utils/mic_energy_gate.dart';
import '../utils/microphone_pitch_smoother.dart';
import '../utils/pitch_from_hz.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/text/section_header.dart';
import 'goal_completion_screen.dart';

final class FretPlayNoteScreen extends StatefulWidget {
  const FretPlayNoteScreen({super.key});

  @override
  State<FretPlayNoteScreen> createState() => _FretPlayNoteScreenState();
}

final class _FretPlayNoteScreenState extends State<FretPlayNoteScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  late List<GuitarNote> _allNotes;
  late List<String> _uniqueNames;

  late String _targetName;
  var _t0 = 0;
  var _feedback = false;
  var _lastOk = false;
  StreamSubscription<PitchFrame>? _pitchSub;
  var _listening = false;
  double? _lastHz;
  String? _lastNoteName;
  final _stable = <String>[];
  static const int _stableNeed = 4;
  var _quietStreak = 0;
  final _hzSmoother = PitchReadingSmoother(
    alpha: 0.1,
    maxJumpCents: 300,
    invalidStreakToReset: 10,
  );
  var _refA4 = PracticePrefs.defaultReferenceA4Hz;

  @override
  void initState() {
    super.initState();
    _allNotes = GuitarNote.allNotes();
    _uniqueNames = _allNotes.map((e) => e.noteName).toSet().toList()..sort();
    _newRound();
    _loadPrefsRef();
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
    _stopMic();
    super.dispose();
  }

  void _newRound() {
    _stopMic();
    setState(() {
      _targetName = _uniqueNames[_rnd.nextInt(_uniqueNames.length)];
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _feedback = false;
      _lastOk = false;
      _lastHz = null;
      _lastNoteName = null;
      _stable.clear();
      _quietStreak = 0;
    });
    _loadPrefsRef();
  }

  void _stopMic() {
    _pitchSub?.cancel();
    _pitchSub = null;
    _quietStreak = 0;
    _hzSmoother.reset();
    if (_listening && mounted) {
      setState(() => _listening = false);
    } else {
      _listening = false;
    }
  }

  Future<void> _tryStartMic() async {
    if (_feedback || _listening) {
      return;
    }
    final st = await Permission.microphone.request();
    if (!mounted) {
      return;
    }
    if (!st.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.guitarPlayDenied)),
      );
      return;
    }
    _quietStreak = 0;
    _hzSmoother.reset();
    _stable.clear();
    _pitchSub = IosPitchDetector.pitchStream.listen(_onPitchSample);
    setState(() => _listening = true);
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

  void _pickOtherTarget() {
    if (_feedback) {
      return;
    }
    final others = _uniqueNames.where((n) => n != _targetName).toList();
    if (others.isEmpty) {
      return;
    }
    _stable.clear();
    _quietStreak = 0;
    setState(() {
      _targetName = others[_rnd.nextInt(others.length)];
      _t0 = DateTime.now().millisecondsSinceEpoch;
      _lastHz = null;
      _lastNoteName = null;
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
    final nested = PitchFromHz.octaveNestForGuitar(hz);
    final smoothed = _hzSmoother.push(nested);
    if (smoothed == null) {
      setState(() {
        _lastHz = null;
        _lastNoteName = null;
      });
      _stable.clear();
      return;
    }
    final midi = PitchFromHz.midiFromHz(smoothed, referenceA4: _refA4);
    if (midi == null) {
      setState(() {
        _lastHz = null;
        _lastNoteName = null;
      });
      _stable.clear();
      return;
    }
    final name = GuitarNote.noteNameForMidi(midi);
    _stable.add(name);
    while (_stable.length > _stableNeed) {
      _stable.removeAt(0);
    }
    setState(() {
      _lastHz = smoothed;
      _lastNoteName = name;
    });
    if (_stable.length == _stableNeed &&
        _stable.every((e) => e == _targetName)) {
      _completeCorrect(midi);
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
    if (!mounted) {
      return;
    }
    setState(() {
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
    final midis = _allNotes
        .where((n) => n.noteName == _targetName)
        .map((n) => n.midi)
        .toList();
    if (midis.isEmpty) {
      return;
    }
    midis.sort();
    await _audio.playMidi(midis[midis.length ~/ 2]);
  }

  @override
  Widget build(BuildContext context) {
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
                            subtitle: _targetName,
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
                                onPressed: _feedback ? null : _pickOtherTarget,
                                icon: Icon(
                                  Icons.swap_horiz_rounded,
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
                          SoftCard(
                            padding: AppSpacing.cardPad,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  AppStrings.guitarPlayMicHint,
                                  style: t.bodySmall?.copyWith(
                                    color: DesignTokens.slate400,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _listening
                                            ? AppStrings.tunerMicActive
                                            : AppStrings.guitarPlayIdle,
                                        style: t.titleSmall?.copyWith(
                                          color: _listening
                                              ? DesignTokens.green400
                                              : DesignTokens.slate300,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  _lastNoteName != null && _lastHz != null
                                      ? '${AppStrings.guitarPlayDetected}: '
                                            '$_lastNoteName · '
                                            '${_lastHz!.toStringAsFixed(0)} Hz'
                                      : '—',
                                  style: t.headlineSmall?.copyWith(
                                    color: DesignTokens.white,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                FilledButton.tonalIcon(
                                  onPressed: _feedback ? null : _toggleMic,
                                  icon: Icon(
                                    _listening
                                        ? Icons.stop_rounded
                                        : Icons.mic_rounded,
                                  ),
                                  label: Text(
                                    _listening
                                        ? AppStrings.guitarPlayStop
                                        : AppStrings.tunerMicResume,
                                  ),
                                ),
                              ],
                            ),
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
