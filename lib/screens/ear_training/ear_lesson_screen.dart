import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../models/ear_question.dart';
import '../../services/ear_question_factory.dart';
import '../../services/ear_session_recorder.dart';
import '../../services/guitar_audio_service.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/ear/ear_fret_answer_board.dart';
import '../../widgets/ear/ear_layout.dart';
import '../../widgets/ear/ear_option_button.dart';
import '../../widgets/ear/ear_palette.dart';
import '../../widgets/ear/interval_anchors_sheet.dart';
import '../../widgets/ear/pitch_keyboard_diagram.dart';
import '../../widgets/motion/motion_entrance.dart';

/// Haftanın gerçek dersi: alıştırmalara girmeden önce konuyu adım adım
/// anlatan, sesli örneklerle desteklenen ekran.
///
/// Kullanıcı geri bildirimi: "her derste kursu da anlatması lazımdı,
/// anlatmamış" — önceden yalnızca [WeekTheoryCard]'daki tek cümlelik ipucu
/// vardı. Bu ekran haftanın [EarWeek.lesson] listesindeki her noktayı sırayla
/// gösterip gerçek bir mini-ders deneyimi sağlar; her nokta önce sesi çaldırır
/// (bu işitsel bir beceri — önce duy), sonra ayrıntılı açıklamayı okutur.
/// Sonunda puanlanmayan, cezasız bir "Hızlı Kontrol" turu ile öğrendiğini
/// hemen deneyebilir.
final class EarLessonScreen extends StatefulWidget {
  const EarLessonScreen({super.key, required this.week, required this.prefsRepo});

  final EarWeek week;
  final PracticePrefsRepository prefsRepo;

  @override
  State<EarLessonScreen> createState() => _EarLessonScreenState();
}

final class _EarLessonScreenState extends State<EarLessonScreen> {
  /// Çalan ses: `'3'` = 3. noktanın ana sesi, `'3b'` = karşılaştırma sesi.
  String? _playingKey;

  late final List<EarQuestion> _warmup = EarQuestionFactory().session(
    kinds: earExpandKinds(widget.week, widget.week.exercises),
    count: 5,
    weekNumber: widget.week.weekNumber,
  );
  late final Map<String, String> _glossary = earGlossaryUpTo(widget.week.weekNumber);
  int _warmupIndex = 0;
  String? _warmupSelectedId;
  int _warmupCorrect = 0;

  @override
  void initState() {
    super.initState();
    unawaited(EarSessionRecorder(widget.prefsRepo).markLessonViewed(widget.week.weekNumber));
    if (_warmup.isNotEmpty) {
      unawaited(GuitarAudioService.instance.playSound(_warmup.first.sound));
    }
  }

  @override
  void dispose() {
    unawaited(GuitarAudioService.instance.stop());
    super.dispose();
  }

  Future<void> _play(int index, {bool compare = false}) async {
    final point = widget.week.lesson[index];
    final sound = compare ? point.compareSound : point.sound;
    if (sound == null) return;
    final key = compare ? '${index}b' : '$index';
    setState(() => _playingKey = key);
    await GuitarAudioService.instance.playSound(sound);
    if (mounted && _playingKey == key) {
      setState(() => _playingKey = null);
    }
  }

  EarOptionState _warmupStateOf(String id, EarQuestion q) {
    final picked = _warmupSelectedId;
    if (picked == null) return EarOptionState.idle;
    if (id == picked) {
      return q.isCorrect(id) ? EarOptionState.correct : EarOptionState.wrong;
    }
    if (q.isCorrect(id)) return EarOptionState.revealedCorrect;
    return EarOptionState.dimmed;
  }

  void _selectWarmup(String id) {
    if (_warmupSelectedId != null) return;
    final q = _warmup[_warmupIndex];
    setState(() {
      _warmupSelectedId = id;
      if (q.isCorrect(id)) _warmupCorrect++;
    });
  }

  void _tapWarmupOption(String id, EarQuestion q) {
    if (_warmupSelectedId == null) {
      _selectWarmup(id);
      return;
    }
    final sound = q.optionById(id)?.sound;
    if (sound != null) unawaited(GuitarAudioService.instance.playSound(sound));
  }

  void _nextWarmup() {
    setState(() {
      _warmupIndex++;
      _warmupSelectedId = null;
    });
    if (_warmupIndex < _warmup.length) {
      unawaited(GuitarAudioService.instance.playSound(_warmup[_warmupIndex].sound));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final week = widget.week;
    final accent = week.isConsolidation ? DesignTokens.earGold : DesignTokens.blue500;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('${EarStrings.weekLabel(week.weekNumber)} · ${EarStrings.lessonBadge}'),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
      ),
      extendBodyBehindAppBar: true,
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              return ListView(
                padding: EarLayout.pagePadding(c.maxWidth),
                children: [
                  Text(
                    week.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: p.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    week.subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: p.textMuted,
                          height: 1.35,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  for (var i = 0; i < week.lesson.length; i++) ...[
                    _LessonPointCard(
                      index: i,
                      point: week.lesson[i],
                      accent: accent,
                      playing: _playingKey == '$i',
                      playingCompare: _playingKey == '${i}b',
                      onListen: week.lesson[i].sound == null ? null : () => _play(i),
                      onListenCompare: week.lesson[i].compareSound == null
                          ? null
                          : () => _play(i, compare: true),
                      onEditAnchors: week.lesson[i].opensAnchorEditor
                          ? () => unawaited(
                                IntervalAnchorsSheet.show(context, widget.prefsRepo),
                              )
                          : null,
                    ).entranceFadeSlide(context, delay: Duration(milliseconds: 80 * i)),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_glossary.isNotEmpty) ...[
                    _GlossarySection(terms: _glossary, accent: accent),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_warmup.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.sm),
                    _SectionLabel(
                      title: EarStrings.lessonWarmupTitle,
                      subtitle: EarStrings.lessonWarmupSubtitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedSwitcher(
                      duration: AppMotion.dur(context, const Duration(milliseconds: 280)),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.04, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _warmupIndex >= _warmup.length
                          ? _WarmupDoneCard(
                              key: const ValueKey('warmup_done'),
                              correct: _warmupCorrect,
                              total: _warmup.length,
                            )
                          : _WarmupCard(
                              key: ValueKey('warmup_card_$_warmupIndex'),
                              question: _warmup[_warmupIndex],
                              index: _warmupIndex,
                              total: _warmup.length,
                              selectedId: _warmupSelectedId,
                              stateOf: (id) => _warmupStateOf(id, _warmup[_warmupIndex]),
                              onTapOption: (id) => _tapWarmupOption(id, _warmup[_warmupIndex]),
                              onReplay: () => unawaited(
                                GuitarAudioService.instance.playSound(_warmup[_warmupIndex].sound),
                              ),
                              onContinue: _nextWarmup,
                            ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text(EarStrings.lessonStartPractice),
                    style: FilledButton.styleFrom(
                      backgroundColor: DesignTokens.earEmerald,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _LessonPointCard extends StatelessWidget {
  const _LessonPointCard({
    required this.index,
    required this.point,
    required this.accent,
    required this.playing,
    required this.onListen,
    this.playingCompare = false,
    this.onListenCompare,
    this.onEditAnchors,
  });

  final int index;
  final LessonPoint point;
  final Color accent;
  final bool playing;
  final VoidCallback? onListen;
  final bool playingCompare;
  final VoidCallback? onListenCompare;
  final VoidCallback? onEditAnchors;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final sound = point.sound;
    final diagramMidis = sound == null ? null : PitchKeyboardDiagram.of(sound);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: t.labelMedium?.copyWith(color: accent, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  point.heading,
                  style: t.titleMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          // Bu işitsel bir beceri: önce sesi duy, sonra ayrıntılı açıklamayı oku.
          if (onListen != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _ListenButton(
              label: point.soundLabel ?? EarStrings.lessonListen,
              color: accent,
              playing: playing,
              badge: onListenCompare != null ? 'A' : null,
              onTap: onListen!,
            ),
          ],
          if (onListenCompare != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _ListenButton(
              label: point.compareLabel ?? EarStrings.lessonListen,
              color: DesignTokens.earRose,
              playing: playingCompare,
              badge: 'B',
              onTap: onListenCompare!,
            ),
            const SizedBox(height: 4),
            Text(
              EarStrings.lessonCompareHint,
              style: t.labelSmall?.copyWith(color: p.textMuted),
            ),
          ],
          if (diagramMidis != null) ...[
            const SizedBox(height: AppSpacing.sm),
            PitchKeyboardDiagram(midis: diagramMidis, accent: accent),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            point.body,
            style: t.bodyMedium?.copyWith(color: p.textSecondary, height: 1.5),
          ),
          if (point.keyIdea != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _CalloutBox(
              icon: Icons.lightbulb_rounded,
              title: EarStrings.lessonKeyIdea,
              color: DesignTokens.earGold,
              child: Text(
                point.keyIdea!,
                style: t.bodyMedium?.copyWith(
                  color: p.textPrimary,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
            ),
          ],
          if (point.terms.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CalloutBox(
              icon: Icons.menu_book_rounded,
              title: EarStrings.lessonTerms,
              color: accent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final e in point.terms.entries)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${e.key}: ',
                              style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w800),
                            ),
                            TextSpan(text: e.value),
                          ],
                        ),
                        style: t.bodySmall?.copyWith(color: p.textSecondary, height: 1.4),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (point.examples.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            _CalloutBox(
              icon: Icons.music_note_rounded,
              title: EarStrings.lessonExamples,
              color: DesignTokens.earEmerald,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final ex in point.examples)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('•  ', style: t.bodySmall?.copyWith(color: p.textSecondary)),
                          Expanded(
                            child: Text(
                              ex,
                              style: t.bodySmall?.copyWith(color: p.textSecondary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (point.tryThis != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _CalloutBox(
              icon: Icons.play_arrow_rounded,
              title: EarStrings.lessonTryThis,
              color: DesignTokens.blue500,
              child: Text(
                point.tryThis!,
                style: t.bodySmall?.copyWith(color: p.textPrimary, height: 1.45),
              ),
            ),
          ],
          if (onEditAnchors != null) ...[
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onEditAnchors,
              icon: const Icon(Icons.library_music_rounded),
              label: const Text(EarStrings.anchorsEdit),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(44)),
            ),
          ],
        ],
      ),
    );
  }
}

final class _ListenButton extends StatelessWidget {
  const _ListenButton({
    required this.label,
    required this.color,
    required this.playing,
    required this.onTap,
    this.badge,
  });

  final String label;
  final Color color;
  final bool playing;
  final VoidCallback onTap;

  /// A/B karşılaştırmasında düğmenin harfi.
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: badge == null ? label : '$badge: $label',
      child: Material(
        color: color.withValues(alpha: p.dark ? 0.18 : 0.1),
        borderRadius: BorderRadius.circular(AppRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadii.md),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                AnimatedScale(
                  scale: playing && !AppMotion.reduced(context) ? 1.08 : 1.0,
                  duration: AppMotion.dur(context, const Duration(milliseconds: 220)),
                  curve: Curves.easeOutBack,
                  child: AnimatedContainer(
                    duration: AppMotion.dur(context, const Duration(milliseconds: 220)),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      boxShadow: playing
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.55),
                                blurRadius: 14,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: badge != null && !playing
                        ? Text(
                            badge!,
                            style: t.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : Icon(
                            playing ? Icons.graphic_eq_rounded : Icons.volume_up_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    label,
                    style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                  ),
                ),
                Icon(
                  playing ? Icons.graphic_eq_rounded : Icons.play_circle_fill_rounded,
                  color: color,
                  size: 26,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _CalloutBox extends StatelessWidget {
  const _CalloutBox({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: p.dark ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: t.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}

/// Bu haftaya kadar derslerde geçen tüm terimler; varsayılan olarak kapalı.
final class _GlossarySection extends StatelessWidget {
  const _GlossarySection({required this.terms, required this.accent});

  final Map<String, String> terms;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(Icons.menu_book_rounded, color: accent),
          title: Text(
            EarStrings.glossaryTitle,
            style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
          ),
          subtitle: Text(
            EarStrings.glossarySubtitle(terms.length),
            style: t.bodySmall?.copyWith(color: p.textMuted),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.md),
          children: [
            for (final e in terms.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '${e.key}\n',
                        style: TextStyle(color: p.textPrimary, fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: e.value),
                    ],
                  ),
                  style: t.bodySmall?.copyWith(color: p.textSecondary, height: 1.4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: t.titleMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: t.bodySmall?.copyWith(color: p.textMuted)),
      ],
    );
  }
}

/// Puanlanmayan, cezasız 2-3 soruluk hızlı kontrol — dersten hemen sonra
/// öğrendiğini denemek için. SRS/hafta barajına hiçbir etkisi yok.
final class _WarmupCard extends StatelessWidget {
  const _WarmupCard({
    super.key,
    required this.question,
    required this.index,
    required this.total,
    required this.selectedId,
    required this.stateOf,
    required this.onTapOption,
    required this.onReplay,
    required this.onContinue,
  });

  final EarQuestion question;
  final int index;
  final int total;
  final String? selectedId;
  final EarOptionState Function(String id) stateOf;
  final void Function(String id) onTapOption;
  final VoidCallback onReplay;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final answered = selectedId != null;
    final correct = answered && question.isCorrect(selectedId!);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  question.prompt,
                  style: t.titleMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                ),
              ),
              Text(
                EarStrings.questionCounter(index + 1, total),
                style: t.labelMedium?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadii.sm),
            onTap: onReplay,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.replay_circle_filled_rounded, color: p.info, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    EarStrings.replay,
                    style: t.labelLarge?.copyWith(color: p.info, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (question.layout == EarAnswerLayout.fretboard)
            EarFretAnswerBoard(options: question.options, stateOf: stateOf, onTap: onTapOption)
          else
            Column(
              children: [
                for (final o in question.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: EarOptionButton(
                      title: o.title,
                      subtitle: o.subtitle,
                      state: stateOf(o.id),
                      showListenIcon: answered && o.sound != null,
                      onTap: () => onTapOption(o.id),
                    ),
                  ),
              ],
            ),
          if (answered) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              correct ? EarStrings.correctTitle : EarStrings.correctAnswerIs(question.correctLabel),
              style: t.bodyMedium?.copyWith(
                color: correct ? p.success : p.danger,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
              child: const Text(EarStrings.continueLabel),
            ),
          ],
        ],
      ),
    );
  }
}

final class _WarmupDoneCard extends StatelessWidget {
  const _WarmupDoneCard({super.key, required this.correct, required this.total});

  final int correct;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: DesignTokens.earEmerald.withValues(alpha: p.dark ? 0.16 : 0.1),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: DesignTokens.earEmerald.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 26)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              EarStrings.lessonWarmupDone(correct, total),
              style: t.titleSmall?.copyWith(color: p.success, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
