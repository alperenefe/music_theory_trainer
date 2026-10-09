import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../audio/ear_sound.dart';
import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../models/ear_exercise_kind.dart';
import '../../models/ear_question.dart';
import '../../models/ear_session_result.dart';
import '../../models/practice_prefs.dart';
import '../../widgets/ear/interval_anchors_sheet.dart';
import '../../services/app_sound_policy.dart';
import '../../services/ear_feedback_tips.dart';
import '../../services/ear_question_factory.dart';
import '../../services/ear_session_recorder.dart';
import '../../services/ear_srs_service.dart';
import '../../services/guitar_audio_service.dart';
import '../../services/practice_prefs_repository.dart';
import '../../services/ui_chime_service.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/ear/ear_feedback_panel.dart';
import '../../widgets/ear/ear_fret_answer_board.dart';
import '../../widgets/ear/ear_layout.dart';
import '../../widgets/ear/ear_option_button.dart';
import '../../widgets/ear/ear_palette.dart';
import '../../widgets/ear/ear_quiz_top_bar.dart';
import '../../widgets/ear/waveform_pulse_widget.dart';
import 'ear_session_summary.dart';

/// Tüm kulak eğitimi egzersizlerinin tek quiz motoru.
///
/// - [kinds] tek türse klasik blok pratik; birden fazlaysa sorular türler
///   arasında dengeli ve karışık gelir (interleaving).
/// - [targetSubtypes] verilirse aralıklı tekrar: sorular bu zayıf noktalara odaklanır.
/// - [EarSessionMode.boss]: 3 can, can bitince tur biter.
final class EarQuizScreen extends StatefulWidget {
  const EarQuizScreen({
    super.key,
    required this.prefsRepo,
    required this.week,
    required this.kinds,
    this.mode = EarSessionMode.practice,
    this.questionCount = 10,
    this.targetSubtypes = const [],
    this.random,
  });

  final PracticePrefsRepository prefsRepo;
  final EarWeek week;
  final List<EarExerciseKind> kinds;
  final EarSessionMode mode;
  final int questionCount;
  final List<String> targetSubtypes;

  /// Testlerde tekrarlanabilir soru sırası için.
  final math.Random? random;

  static const bossHearts = 3;
  static const bossQuestionCount = 15;

  /// Kayıtta kullanılacak tür: tek türse o, karışıksa [EarExerciseKind.interleaved].
  EarExerciseKind get resultKind {
    final concrete = kinds.where((k) => k != EarExerciseKind.interleaved).toSet();
    return concrete.length == 1 ? concrete.first : EarExerciseKind.interleaved;
  }

  @override
  State<EarQuizScreen> createState() => _EarQuizScreenState();
}

enum _Phase { quiz, saving, summary }

final class _EarQuizScreenState extends State<EarQuizScreen> {
  final _audio = GuitarAudioService.instance;
  final _srs = EarSrsService();
  final _focusNode = FocusNode(debugLabel: 'earQuiz');

  late EarQuestionFactory _factory;
  late List<EarQuestion> _questions;
  var _phase = _Phase.quiz;
  var _index = 0;
  String? _pickedId;
  var _correct = 0;
  var _combo = 0;
  var _bestCombo = 0;
  int? _hearts;
  final _errors = <String, int>{};
  final _attempts = <String, int>{};
  final _latenciesMs = <int>[];
  late DateTime _sessionStart;
  late DateTime _questionShownAt;
  DateTime? _listenReadyAt;
  var _isPlaying = false;
  var _playToken = 0;
  var _round = 0;
  var _soundEnabled = AppSoundPolicy.instance.enabled;
  Future<void> _srsChain = Future<void>.value();
  Map<String, String> _anchors = const {};

  EarSessionResult? _result;
  EarSessionOutcome? _outcome;

  EarQuestion get _q => _questions[_index];
  bool get _answered => _pickedId != null;
  bool get _isBoss => widget.mode == EarSessionMode.boss;

  Color get _accent => switch (widget.mode) {
        EarSessionMode.boss => DesignTokens.earGold,
        EarSessionMode.review => DesignTokens.violet500,
        EarSessionMode.practice => switch (widget.resultKind) {
            EarExerciseKind.intervalBlind => DesignTokens.earAmber,
            EarExerciseKind.harmonicRhythm => DesignTokens.streakOrange,
            EarExerciseKind.chordQuality => DesignTokens.earEmerald,
            EarExerciseKind.bassHunter => DesignTokens.earCyan,
            EarExerciseKind.inversionDetect => DesignTokens.earRose,
            EarExerciseKind.cadenceRecognition => DesignTokens.earViolet,
            EarExerciseKind.scaleDegree => DesignTokens.earGold,
            EarExerciseKind.interleaved => DesignTokens.blue500,
          },
      };

  @override
  void initState() {
    super.initState();
    _factory = EarQuestionFactory(random: widget.random);
    _resetSession();
    _schedulePlay();
    unawaited(_loadAnchors());
  }

  Future<void> _loadAnchors() async {
    final prefs = await widget.prefsRepo.load();
    if (mounted) setState(() => _anchors = prefs.intervalAnchors);
  }

  /// Aralık sorusunda doğru cevabın şarkı çapası anahtarı.
  String? _anchorKeyFor(EarQuestion q) {
    final s = q.sound;
    if (q.kind != EarExerciseKind.intervalBlind || s is! IntervalSound) return null;
    return PracticePrefs.anchorKey(q.subtypeKey, descending: s.descending);
  }

  Future<void> _addSong(String key) async {
    final saved = await IntervalAnchorsSheet.show(context, widget.prefsRepo, focusKey: key);
    if (saved != null && mounted) setState(() => _anchors = saved);
  }

  @override
  void dispose() {
    _playToken++;
    unawaited(_audio.stop());
    _focusNode.dispose();
    super.dispose();
  }

  void _resetSession() {
    final count = _isBoss ? EarQuizScreen.bossQuestionCount : widget.questionCount;
    _questions = _factory.session(
      kinds: widget.kinds,
      count: count,
      weekNumber: widget.week.weekNumber,
      subtypes: widget.targetSubtypes,
    );
    _round++;
    _index = 0;
    _pickedId = null;
    _correct = 0;
    _combo = 0;
    _bestCombo = 0;
    _hearts = _isBoss ? EarQuizScreen.bossHearts : null;
    _errors.clear();
    _attempts.clear();
    _latenciesMs.clear();
    _sessionStart = DateTime.now();
    _questionShownAt = _sessionStart;
    _listenReadyAt = null;
    _result = null;
    _outcome = null;
  }

  /// İlk karede otomatik dinlet (setState'i build dışında çağırmak için).
  void _schedulePlay() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _phase == _Phase.quiz) _playQuestion();
    });
  }

  // --- Ses ------------------------------------------------------------------

  Future<void> _play(EarSound sound, {bool marksListenReady = false}) async {
    final token = ++_playToken;
    if (mounted) setState(() => _isPlaying = _soundEnabled);
    await _audio.playSound(sound);
    if (!mounted || token != _playToken) return;
    setState(() => _isPlaying = false);
    if (marksListenReady) _listenReadyAt ??= DateTime.now();
  }

  Future<void> _playQuestion() => _play(_q.sound, marksListenReady: true);

  Future<void> _enableSound() async {
    AppSoundPolicy.instance.setEnabled(true);
    setState(() => _soundEnabled = true);
    try {
      final prefs = await widget.prefsRepo.load();
      await widget.prefsRepo.save(prefs.copyWith(soundEnabled: true));
    } catch (e) {
      debugPrint('EarQuizScreen: ses tercihi kaydedilemedi: $e');
    }
    if (mounted && _phase == _Phase.quiz) unawaited(_playQuestion());
  }

  // --- Akış -----------------------------------------------------------------

  void _select(String optionId) {
    if (_phase != _Phase.quiz) return;
    final q = _q;

    // Cevaptan sonra seçeneğe dokunmak = o seçeneğin sesini dinlemek.
    if (_answered) {
      final s = q.optionById(optionId)?.sound;
      if (s != null) unawaited(_play(s));
      return;
    }

    final ok = q.isCorrect(optionId);
    final readyAt = _listenReadyAt ?? _questionShownAt;
    final latency = DateTime.now().difference(readyAt).inMilliseconds;

    setState(() {
      _pickedId = optionId;
      _latenciesMs.add(math.max(0, latency));
      _attempts[q.subtypeKey] = (_attempts[q.subtypeKey] ?? 0) + 1;
      if (ok) {
        _correct++;
        _combo++;
        _bestCombo = math.max(_bestCombo, _combo);
      } else {
        _combo = 0;
        _errors[q.subtypeKey] = (_errors[q.subtypeKey] ?? 0) + 1;
        if (_hearts != null) _hearts = _hearts! - 1;
      }
    });

    if (ok) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.mediumImpact();
    }
    unawaited(UiChimeService.instance.play(ok));

    // SRS yazımlarını sıraya al: art arda load/save yarışı olmasın.
    _srsChain = _srsChain.then((_) async {
      try {
        await _srs.recordAttempt(
          cardKey: q.subtypeKey,
          correct: ok,
          latencyMs: math.max(0, latency),
        );
      } catch (e) {
        debugPrint('EarQuizScreen: SRS kaydı başarısız: $e');
      }
    });
  }

  void _selectByIndex(int i) {
    if (_phase != _Phase.quiz || _q.layout != EarAnswerLayout.choices) return;
    if (i < 0 || i >= _q.options.length) return;
    _select(_q.options[i].id);
  }

  bool get _isLastStep {
    if (_hearts != null && _hearts! <= 0) return true;
    return _index + 1 >= _questions.length;
  }

  void _continue() {
    if (_phase != _Phase.quiz || !_answered) return;
    if (_isLastStep) {
      unawaited(_finish());
      return;
    }
    setState(() {
      _index++;
      _pickedId = null;
      _questionShownAt = DateTime.now();
      _listenReadyAt = null;
    });
    unawaited(_playQuestion());
  }

  Future<void> _finish() async {
    _playToken++;
    setState(() {
      _phase = _Phase.saving;
      _isPlaying = false;
    });

    final result = EarSessionResult(
      kind: widget.resultKind,
      weekNumber: widget.week.weekNumber,
      totalQuestions: _index + 1,
      correctCount: _correct,
      errorsBySubtype: Map.of(_errors),
      attemptsBySubtype: Map.of(_attempts),
      durationSeconds: DateTime.now().difference(_sessionStart).inSeconds,
      completedAt: DateTime.now(),
      mode: widget.mode,
    );

    EarSessionOutcome? outcome;
    try {
      await _srsChain;
      outcome = await EarSessionRecorder(widget.prefsRepo).record(result);
    } catch (e, st) {
      debugPrint('EarQuizScreen: seans kaydedilemedi: $e\n$st');
    }

    if (!mounted) return;
    setState(() {
      _result = result;
      _outcome = outcome;
      _phase = _Phase.summary;
    });
  }

  void _playAgain() {
    setState(() {
      _phase = _Phase.quiz;
      _resetSession();
    });
    _focusNode.requestFocus();
    _schedulePlay();
  }

  bool get _canPopFreely =>
      _phase != _Phase.quiz || (_index == 0 && !_answered);

  Future<void> _requestExit() async {
    if (_canPopFreely) {
      Navigator.of(context).pop();
      return;
    }
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(EarStrings.exitTitle),
        content: const Text(EarStrings.exitBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(EarStrings.exitConfirm),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(EarStrings.exitCancel),
          ),
        ],
      ),
    );
    if (leave == true && mounted) Navigator.of(context).pop();
  }

  // --- Görünüm --------------------------------------------------------------

  EarOptionState _stateOf(String id) {
    final picked = _pickedId;
    if (picked == null) return EarOptionState.idle;
    final q = _q;
    if (id == picked) {
      return q.isCorrect(id) ? EarOptionState.correct : EarOptionState.wrong;
    }
    // Birden fazla doğru konum olabilir (bas avcısı): hepsini göster.
    if (q.isCorrect(id)) return EarOptionState.revealedCorrect;
    return EarOptionState.dimmed;
  }

  Map<ShortcutActivator, VoidCallback> get _shortcuts {
    const digits = [
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];
    const numpad = [
      LogicalKeyboardKey.numpad1,
      LogicalKeyboardKey.numpad2,
      LogicalKeyboardKey.numpad3,
      LogicalKeyboardKey.numpad4,
      LogicalKeyboardKey.numpad5,
      LogicalKeyboardKey.numpad6,
      LogicalKeyboardKey.numpad7,
      LogicalKeyboardKey.numpad8,
      LogicalKeyboardKey.numpad9,
    ];
    return {
      for (var i = 0; i < digits.length; i++) SingleActivator(digits[i]): () => _selectByIndex(i),
      for (var i = 0; i < numpad.length; i++) SingleActivator(numpad[i]): () => _selectByIndex(i),
      const SingleActivator(LogicalKeyboardKey.space): () {
        if (_phase == _Phase.quiz) unawaited(_playQuestion());
      },
      const SingleActivator(LogicalKeyboardKey.enter): _continue,
      const SingleActivator(LogicalKeyboardKey.numpadEnter): _continue,
      const SingleActivator(LogicalKeyboardKey.escape): () => unawaited(_requestExit()),
    };
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _canPopFreely,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_requestExit());
      },
      child: CallbackShortcuts(
        bindings: _shortcuts,
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          child: Scaffold(
            body: MeshGradientBackdrop(
              child: SafeArea(
                bottom: false,
                child: switch (_phase) {
                  _Phase.quiz => _buildQuiz(context),
                  _Phase.saving => SafeArea(
                      top: false,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              EarStrings.saving,
                              style: TextStyle(color: EarPalette.of(context).textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  _Phase.summary => SafeArea(
                      top: false,
                      child: EarSessionSummary(
                        result: _result!,
                        outcome: _outcome,
                        week: widget.week,
                        latenciesMs: List.unmodifiable(_latenciesMs),
                        bestCombo: _bestCombo,
                        heartsLeft: _hearts,
                        onPlayAgain: _playAgain,
                        onDone: () => Navigator.of(context).pop(),
                        prefsRepo: widget.prefsRepo,
                      ),
                    ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuiz(BuildContext context) {
    final q = _q;
    final answeredCount = _index + (_answered ? 1 : 0);

    return Column(
      children: [
        EarQuizTopBar(
          onClose: () => unawaited(_requestExit()),
          progress: answeredCount / _questions.length,
          accentColor: _accent,
          counterLabel: EarStrings.questionCounter(_index + 1, _questions.length),
          hearts: _hearts,
          maxHearts: EarQuizScreen.bossHearts,
          combo: _combo,
        ),
        if (!_soundEnabled) _SoundOffBanner(onEnable: _enableSound),
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final twoPane = c.maxWidth >= EarLayout.twoPaneMinWidth;
              final compactHeight = c.maxHeight < 560;
              final listen = _buildListenArea(context, q, compact: compactHeight && !twoPane);
              final answers = _buildAnswers(context, q);

              if (twoPane) {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: listen,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xxl),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                                child: answers,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              // Dar ekran: içerik sığarsa dinleme üstte, cevaplar başparmak
              // bölgesinde (altta); sığmazsa kaydırılır — taşma (overflow) olmaz.
              const top = AppSpacing.xs;
              const bottom = AppSpacing.md;
              final side = math.max(AppSpacing.md, (c.maxWidth - 640) / 2);
              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(side, top, side, bottom),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: math.max(0.0, c.maxHeight - top - bottom),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      listen,
                      const SizedBox(height: AppSpacing.lg),
                      answers,
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (_answered)
          EarMaxWidth(
            maxWidth: 1120,
            child: _buildFeedback(q),
          )
        else
          const SafeArea(top: false, child: SizedBox(height: AppSpacing.xs)),
      ],
    );
  }

  Widget _buildListenArea(BuildContext context, EarQuestion q, {required bool compact}) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final showKind = widget.resultKind == EarExerciseKind.interleaved ||
        widget.mode != EarSessionMode.practice;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _Tag(
              label: switch (widget.mode) {
                EarSessionMode.boss => '👑 ${widget.week.bossTitle ?? EarStrings.weekLabel(widget.week.weekNumber)}',
                EarSessionMode.review => '🧠 ${EarStrings.reviewSessionTitle}',
                EarSessionMode.practice => EarStrings.weekLabel(widget.week.weekNumber),
              },
              color: _accent,
            ),
            if (showKind) _Tag(label: '${q.kind.emoji} ${q.kind.label}', color: p.textMuted),
          ],
        ),
        SizedBox(height: compact ? AppSpacing.sm : AppSpacing.lg),
        WaveformPulseWidget(
          isPlaying: _isPlaying,
          accentColor: _accent,
          size: compact ? 104 : 136,
          onPlayTap: () => unawaited(_playQuestion()),
          label: _isPlaying ? EarStrings.playing : EarStrings.replay,
        ),
        if (q.altSound != null && (!q.altSoundAfterAnswer || _answered)) ...[
          const SizedBox(height: AppSpacing.xs),
          TextButton.icon(
            onPressed: () => unawaited(_play(q.altSound!)),
            icon: const Icon(Icons.hearing_rounded, size: 18),
            label: Text(q.altSoundLabel ?? EarStrings.replay),
          ),
        ],
        SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
        Text(
          q.prompt,
          textAlign: TextAlign.center,
          style: t.headlineSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          q.hint,
          textAlign: TextAlign.center,
          style: t.bodyMedium?.copyWith(color: p.textMuted),
        ),
        if (EarLayout.showKeyboardHints && q.layout == EarAnswerLayout.choices) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            EarStrings.keyboardHint,
            textAlign: TextAlign.center,
            style: t.labelSmall?.copyWith(color: p.textMuted),
          ),
        ],
      ],
    );
  }

  Widget _buildAnswers(BuildContext context, EarQuestion q) {
    if (q.layout == EarAnswerLayout.fretboard) {
      return EarFretAnswerBoard(
        key: ValueKey('board_${_round}_$_index'),
        options: q.options,
        stateOf: _stateOf,
        onTap: _select,
      );
    }

    final showShortcuts = EarLayout.showKeyboardHints;
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= EarLayout.optionGridMinWidth ? 2 : 1;
        const gap = AppSpacing.sm;
        final itemWidth = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (var i = 0; i < q.options.length; i++)
              SizedBox(
                width: itemWidth,
                child: EarOptionButton(
                  key: ValueKey('opt_${_round}_${_index}_${q.options[i].id}'),
                  title: q.options[i].title,
                  subtitle: q.options[i].subtitle,
                  state: _stateOf(q.options[i].id),
                  accentColor: _accent,
                  shortcutLabel: showShortcuts && i < 9 ? '${i + 1}' : null,
                  showListenIcon: _answered && q.options[i].sound != null,
                  onTap: () => _select(q.options[i].id),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildFeedback(EarQuestion q) {
    final picked = q.optionById(_pickedId!);
    final ok = q.isCorrect(_pickedId!);
    final isFret = q.layout == EarAnswerLayout.fretboard;
    final yourLabel = picked == null
        ? null
        : (isFret && picked.stringNumber != null && picked.fret != null
            ? EarStrings.fretPosition(picked.stringNumber!, picked.fret!)
            : picked.title);
    final showCombo = ok && _combo >= 3;
    final anchorKey = _anchorKeyFor(q);

    return EarFeedbackPanel(
      key: ValueKey('feedback_${_round}_$_index'),
      correct: ok,
      correctLabel: q.correctLabel,
      yourLabel: yourLabel,
      explanation: q.explanation,
      contrastTip: ok ? null : EarFeedbackTips.contrast(q, _pickedId!),
      yourSong: anchorKey == null ? null : _anchors[anchorKey],
      onAddSong: anchorKey == null ? null : () => unawaited(_addSong(anchorKey)),
      comboMessage: showCombo ? EarStrings.comboToast(_combo) : null,
      compareHint: isFret ? EarStrings.compareFretHint : EarStrings.compareHint,
      onListenYours: picked?.sound == null ? null : () => unawaited(_play(picked!.sound!)),
      onListenCorrect: () => unawaited(_play(q.sound)),
      continueLabel: _isLastStep ? EarStrings.finishLabel : EarStrings.continueLabel,
      onContinue: _continue,
    );
  }
}

final class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: EarPalette.of(context).textSecondary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

final class _SoundOffBanner extends StatelessWidget {
  const _SoundOffBanner({required this.onEnable});

  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return EarMaxWidth(
      maxWidth: 640,
      child: Container(
        margin: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
        padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
        decoration: BoxDecoration(
          color: DesignTokens.earAmber.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadii.sm),
          border: Border.all(color: DesignTokens.earAmber.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            const Icon(Icons.volume_off_rounded, color: DesignTokens.earAmber),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    EarStrings.soundOffTitle,
                    style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                  ),
                  Text(EarStrings.soundOffBody, style: t.bodySmall?.copyWith(color: p.textSecondary)),
                ],
              ),
            ),
            TextButton(onPressed: onEnable, child: const Text(EarStrings.soundOn)),
          ],
        ),
      ),
    );
  }
}
