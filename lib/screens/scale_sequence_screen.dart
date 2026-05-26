import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/practice_attempt.dart';
import '../services/goal_tracker.dart';
import '../services/guitar_audio_service.dart';
import '../services/practice_prefs_repository.dart';
import '../services/practice_session_tracker.dart';
import '../services/stats_repository.dart';
import '../theory/music_scale.dart';
import '../theory/theory_note_labels.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/feedback_bottom_bar.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/text/section_header.dart';
import 'goal_completion_screen.dart';

final class ScaleSequenceScreen extends StatefulWidget {
  const ScaleSequenceScreen({
    super.key,
    required this.poolMinMidi,
    required this.poolMaxMidi,
  });

  final int poolMinMidi;
  final int poolMaxMidi;

  @override
  State<ScaleSequenceScreen> createState() => _ScaleSequenceScreenState();
}

final class _ScaleSequenceScreenState extends State<ScaleSequenceScreen> {
  final _rnd = Random();
  final _repo = StatsRepository();
  final _prefsRepo = PracticePrefsRepository();
  final _audio = GuitarAudioService.instance;
  final _stopwatch = Stopwatch();
  final _session = PracticeSessionTracker();

  late int _rootMidi;
  late ScaleMode _mode;
  late List<ScaleDegree> _degrees;
  final _pickedLabels = <String>[];
  var _step = 0;
  var _roundActive = false;
  var _feedback = false;
  var _lastOk = false;
  var _finalMs = 0;
  String? _flashWrong;
  String? _wrongYour;
  String? _wrongCorrect;

  @override
  void initState() {
    super.initState();
    _newRound();
  }

  @override
  void dispose() {
    _stopwatch.stop();
    super.dispose();
  }

  void _newRound() {
    _stopwatch.stop();
    _stopwatch.reset();
    _rootMidi = widget.poolMinMidi +
        _rnd.nextInt(max(1, widget.poolMaxMidi - widget.poolMinMidi + 1));
    _mode = ScaleMode.values[_rnd.nextInt(ScaleMode.values.length)];
    _degrees = MusicScale.spelledDegrees(_rootMidi, _mode);
    _pickedLabels.clear();
    _step = 0;
    _roundActive = true;
    _feedback = false;
    _lastOk = false;
    _finalMs = 0;
    _flashWrong = null;
    _wrongYour = null;
    _wrongCorrect = null;
    _stopwatch.start();
    setState(() {});
    unawaited(_audio.playMidi(_degrees.first.midi));
  }

  String get _expectedLabel => _degrees[_step].label;

  Future<void> _pick(String label) async {
    if (!_roundActive || _feedback) {
      return;
    }
    if (label == _expectedLabel) {
      setState(() {
        _pickedLabels.add(label);
        _flashWrong = null;
      });
      await _audio.playMidi(_degrees[_step].midi);
      if (_step >= _degrees.length - 1) {
        await _completeScale();
        return;
      }
      setState(() => _step++);
      return;
    }

    setState(() {
      _flashWrong = label;
      _wrongYour = label;
      _wrongCorrect = _expectedLabel;
    });
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (!mounted) {
      return;
    }
    await _finishRound(correct: false, lastMidi: _degrees[_step].midi);
    if (!mounted) {
      return;
    }
    _newRound();
  }

  Future<void> _completeScale() async {
    _stopwatch.stop();
    _roundActive = false;
    _finalMs = _stopwatch.elapsedMilliseconds;
    await _finishRound(correct: true, lastMidi: _degrees.last.midi);
  }

  Future<void> _finishRound({required bool correct, required int lastMidi}) async {
    final ms = correct ? _finalMs : _stopwatch.elapsedMilliseconds;
    await _repo.append(
      PracticeAttempt(
        exercise: AppStrings.exerciseScale,
        midi: lastMidi,
        correct: correct,
        latencyMs: ms,
        atMillis: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    if (!mounted) {
      return;
    }
    _session.record(correct);
    setState(() {
      _feedback = correct;
      _lastOk = correct;
    });
    final done = await GoalTracker.onAttemptRecorded(
      exercise: AppStrings.exerciseScale,
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

  String _formatElapsed() {
    if (!_stopwatch.isRunning && _finalMs > 0) {
      return _formatMs(_finalMs);
    }
    return _formatMs(_stopwatch.elapsedMilliseconds);
  }

  static String _formatMs(int ms) {
    final s = (ms / 1000).toStringAsFixed(1);
    return '$s sn';
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final total = _degrees.length;
    final prompt = MusicScale.fullScalePrompt(_rootMidi, _mode);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: MeshGradientBackdrop(
              child: SafeArea(
                child: Column(
                  children: [
                    ExerciseScreenTopBar(
                      title: AppStrings.scaleTitle,
                      modeLabel: AppStrings.practiceModeScale,
                      sessionCorrect: _session.correct,
                      sessionTotal: _session.total,
                    ),
                    Expanded(
                      child: ListView(
                        padding: AppSpacing.screenHV,
                        children: [
                          Text(
                            AppStrings.scaleDesc,
                            style: t.bodyMedium?.copyWith(
                              color: DesignTokens.slate400,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 20,
                                color: _roundActive
                                    ? DesignTokens.violet400
                                    : DesignTokens.green400,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                '${AppStrings.scaleTimerLabel}: ${_formatElapsed()}',
                                style: t.titleSmall?.copyWith(
                                  color: DesignTokens.slate200,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                MusicScale.stepHint(_step, total),
                                style: t.labelMedium?.copyWith(
                                  color: DesignTokens.slate400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          LinearProgressIndicator(
                            value: _step / total,
                            backgroundColor: DesignTokens.slate800,
                            color: DesignTokens.violet400,
                            minHeight: 8,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SectionHeader(
                            title: AppStrings.questionLabel,
                            subtitle: prompt,
                            subtitleStyle: t.titleMedium?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (_pickedLabels.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            SoftCard(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    AppStrings.scaleSelectedNotesTitle,
                                    style: t.labelMedium?.copyWith(
                                      color: DesignTokens.slate400,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  _ScaleSequenceChipRow(labels: _pickedLabels),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              for (final name in TheoryNoteLabels.chromaticPalette)
                                _ScalePaletteButton(
                                  label: name,
                                  isWrongFlash: _flashWrong == name,
                                  isPicked: _pickedLabels.contains(name),
                                  enabled: _roundActive && !_feedback,
                                  onTap: () => _pick(name),
                                ),
                            ],
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
            wrongYourAnswer: _wrongYour,
            wrongCorrectAnswer: _wrongCorrect,
            successDetail: _lastOk
                ? '${AppStrings.scaleTime}: ${_formatMs(_finalMs)}'
                : null,
          ),
        ],
      ),
    );
  }
}

/// ZIP: seçilen notalar ok ile sıralı chip.
final class _ScaleSequenceChipRow extends StatelessWidget {
  const _ScaleSequenceChipRow({required this.labels});

  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final chips = <Widget>[];
    for (var i = 0; i < labels.length; i++) {
      if (i > 0) {
        chips.add(
          Icon(
            Icons.arrow_forward_rounded,
            size: 16,
            color: DesignTokens.slate500,
          ),
        );
      }
      chips.add(
        Chip(
          label: Text(
            labels[i],
            style: t.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          backgroundColor: DesignTokens.violet400.withValues(alpha: 0.22),
          side: BorderSide(
            color: DesignTokens.violet400.withValues(alpha: 0.55),
          ),
        ),
      );
    }
    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

final class _ScalePaletteButton extends StatelessWidget {
  const _ScalePaletteButton({
    required this.label,
    required this.isWrongFlash,
    required this.isPicked,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool isWrongFlash;
  final bool isPicked;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    var border = DesignTokens.borderSubtle;
    var bg = DesignTokens.slate900.withValues(alpha: 0.45);
    if (isWrongFlash) {
      border = DesignTokens.rose400;
      bg = DesignTokens.rose400.withValues(alpha: 0.2);
    } else if (isPicked) {
      border = DesignTokens.green400.withValues(alpha: 0.5);
      bg = DesignTokens.green400.withValues(alpha: 0.12);
    }
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        child: Ink(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            border: Border.all(color: border),
            color: bg,
          ),
          child: Text(
            label,
            style: t.labelLarge?.copyWith(
              color: enabled ? DesignTokens.white : DesignTokens.slate600,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
