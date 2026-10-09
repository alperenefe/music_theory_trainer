import 'dart:async';

import 'package:flutter/material.dart';

import '../../audio/ear_audio_types.dart';
import '../../audio/ear_sound.dart';
import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../models/ear_exercise_kind.dart';
import '../../models/ear_session_result.dart';
import '../../models/weekly_progress.dart';
import '../../services/ear_curriculum_service.dart';
import '../../services/guitar_audio_service.dart';
import '../../services/practice_prefs_repository.dart';
import '../../services/weekly_mastery_gate.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/ear/ear_layout.dart';
import '../../widgets/ear/ear_palette.dart';
import '../../widgets/ear/gate_criteria_list.dart';
import '../../widgets/ear/week_theory_card.dart';
import '../../widgets/motion/pressable_scale.dart';
import 'ear_lesson_screen.dart';
import 'ear_quiz_screen.dart';
import 'weekly_reflection_sheet.dart';

final class EarWeekDetailScreen extends StatefulWidget {
  const EarWeekDetailScreen({
    super.key,
    required this.week,
    required this.progress,
    required this.prefsRepo,
  });

  final EarWeek week;
  final WeeklyProgress progress;
  final PracticePrefsRepository prefsRepo;

  @override
  State<EarWeekDetailScreen> createState() => _EarWeekDetailScreenState();
}

final class _EarWeekDetailScreenState extends State<EarWeekDetailScreen> {
  late WeeklyProgress _progress = widget.progress;

  EarWeek get _week => widget.week;

  @override
  void dispose() {
    unawaited(GuitarAudioService.instance.stop());
    super.dispose();
  }

  Future<void> _refresh() async {
    final prefs = await widget.prefsRepo.load();
    final p = const EarCurriculumService()
        .progressForWeek(_week.weekNumber, prefs.earWeekProgress);
    if (!mounted) return;
    setState(() => _progress = p);
  }

  Future<void> _playDemo() async {
    final kinds = earExpandKinds(_week, _week.exercises);
    final EarSound sound = switch (kinds.first) {
      EarExerciseKind.intervalBlind =>
        const IntervalSound(rootMidi: 45, interval: EarIntervalType.minor3),
      EarExerciseKind.harmonicRhythm =>
        const HarmonicRhythmSound(
          chords: [
            [48, 52, 55, 60],
            [45, 48, 52, 57],
          ],
          beatsPerChord: 4,
        ),
      EarExerciseKind.chordQuality =>
        const ChordSound(rootMidi: 45, quality: EarChordQuality.minor),
      EarExerciseKind.bassHunter =>
        const NoteSound(45),
      EarExerciseKind.inversionDetect =>
        const SlashChordSound(bassMidi: 40, upperMidis: [48, 52, 55, 60]),
      EarExerciseKind.scaleDegree =>
        const ScaleSound(notes: [48, 52, 55, 60, 55, 52, 48, 59], stepDurationMs: 330),
      EarExerciseKind.cadenceRecognition =>
        const CadenceSound(rootMidi: 45, cadence: EarCadenceType.i_VI),
      _ => const ChordSound(rootMidi: 45, quality: EarChordQuality.major),
    };
    await GuitarAudioService.instance.playSound(sound);
  }

  Future<void> _openLesson() async {
    unawaited(GuitarAudioService.instance.stop());
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EarLessonScreen(week: _week, prefsRepo: widget.prefsRepo),
      ),
    );
    await _refresh();
  }

  Future<void> _launch(List<EarExerciseKind> kinds, {EarSessionMode mode = EarSessionMode.practice}) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EarQuizScreen(
          prefsRepo: widget.prefsRepo,
          week: _week,
          kinds: kinds,
          mode: mode,
        ),
      ),
    );
    await _refresh();
  }

  Future<void> _reflect() async {
    final saved = await showWeeklyReflectionSheet(
      context: context,
      week: _week,
      progress: _progress,
      prefsRepo: widget.prefsRepo,
    );
    if (saved) await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(EarStrings.weekLabel(_week.weekNumber)),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: EarStrings.reflectionTooltip,
            icon: Icon(
              _progress.hasReflection ? Icons.psychology_rounded : Icons.psychology_outlined,
            ),
            onPressed: _reflect,
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 900;
              final left = <Widget>[
                _LessonEntryCard(week: _week, viewed: _progress.lessonViewed, onTap: _openLesson),
                const SizedBox(height: AppSpacing.md),
                WeekTheoryCard(week: _week, onPlayAudioDemo: _playDemo),
                const SizedBox(height: AppSpacing.md),
                _GateCard(progress: _progress, week: _week),
              ];
              final right = <Widget>[
                const _SectionTitle(EarStrings.exercisesTitle),
                const SizedBox(height: AppSpacing.sm),
                for (final kind in _week.exercises)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ExerciseCard(
                      kind: kind,
                      mixedKinds: kind == EarExerciseKind.interleaved
                          ? earKindsIntroducedBy(_week.weekNumber)
                          : const [],
                      onTap: () => _launch([kind]),
                    ),
                  ),
                if (_week.bossTitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _BossCard(
                    title: _week.bossTitle!,
                    cleared: _progress.bossCleared,
                    onTap: () => _launch(
                      earExpandKinds(_week, _week.exercises),
                      mode: EarSessionMode.boss,
                    ),
                  ),
                ],
              ];

              if (wide) {
                return SingleChildScrollView(
                  padding: EarLayout.pagePadding(c.maxWidth, maxWidth: 1080),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: left)),
                      const SizedBox(width: AppSpacing.xl),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: right)),
                    ],
                  ),
                );
              }
              return ListView(
                padding: EarLayout.pagePadding(c.maxWidth),
                children: [
                  ...left,
                  const SizedBox(height: AppSpacing.lg),
                  ...right,
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

final class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: EarPalette.of(context).textPrimary,
            fontWeight: FontWeight.w900,
          ),
    );
  }
}

final class _LessonEntryCard extends StatelessWidget {
  const _LessonEntryCard({required this.week, required this.viewed, required this.onTap});

  final EarWeek week;
  final bool viewed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    const accent = DesignTokens.blue500;

    return PressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${EarStrings.lessonCtaTitle}. ${EarStrings.lessonCtaSubtitle}',
        excludeSemantics: true,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: p.dark ? 0.24 : 0.14),
                DesignTokens.violet500.withValues(alpha: p.dark ? 0.14 : 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(color: accent, width: 1.4),
          ),
          child: Row(
            children: [
              Text(viewed ? '✅' : '📖', style: const TextStyle(fontSize: 30)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      EarStrings.lessonCtaTitle,
                      style: t.titleMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      viewed ? EarStrings.lessonCtaDoneSubtitle : EarStrings.lessonCtaSubtitle,
                      style: t.bodySmall?.copyWith(color: p.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      EarStrings.lessonStepsMeta(week.lesson.length),
                      style: t.labelSmall?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: p.info, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

final class _GateCard extends StatelessWidget {
  const _GateCard({required this.progress, required this.week});

  final WeeklyProgress progress;
  final EarWeek week;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final done = progress.isCompleted;
    final status = WeeklyMasteryGate.status(progress, week);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: done ? DesignTokens.earEmerald : p.border, width: done ? 1.6 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.verified_rounded : Icons.flag_rounded,
                color: done ? p.success : p.info,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  done ? EarStrings.gateDoneTitle : EarStrings.gateTitle,
                  style: t.titleMedium?.copyWith(
                    color: done ? p.success : p.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          GateCriteriaList(status: status, showDaysHint: !done),
        ],
      ),
    );
  }
}

final class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({required this.kind, required this.mixedKinds, required this.onTap});

  final EarExerciseKind kind;
  final List<EarExerciseKind> mixedKinds;
  final VoidCallback onTap;

  Color get _accent => switch (kind) {
        EarExerciseKind.intervalBlind => DesignTokens.earAmber,
        EarExerciseKind.harmonicRhythm => DesignTokens.streakOrange,
        EarExerciseKind.chordQuality => DesignTokens.earEmerald,
        EarExerciseKind.bassHunter => DesignTokens.earCyan,
        EarExerciseKind.inversionDetect => DesignTokens.earRose,
        EarExerciseKind.cadenceRecognition => DesignTokens.earViolet,
        EarExerciseKind.scaleDegree => DesignTokens.earGold,
        EarExerciseKind.interleaved => DesignTokens.blue500,
      };

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final subtitle = mixedKinds.isEmpty
        ? kind.description
        : '${EarStrings.mixedFrom}${mixedKinds.map((k) => k.label).join(' + ')}';

    return PressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: '${kind.label}. $subtitle',
        excludeSemantics: true,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: p.surface,
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: p.border),
            boxShadow: [BoxShadow(color: p.shadow, blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(kind.emoji, style: const TextStyle(fontSize: 24)),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      kind.label,
                      style: t.titleMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: t.bodySmall?.copyWith(color: p.textMuted)),
                    const SizedBox(height: 2),
                    Text(
                      EarStrings.exerciseMeta(10),
                      style: t.labelSmall?.copyWith(color: p.textMuted, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              Icon(Icons.play_circle_fill_rounded, color: _accent, size: 36),
            ],
          ),
        ),
      ),
    );
  }
}

final class _BossCard extends StatelessWidget {
  const _BossCard({required this.title, required this.cleared, required this.onTap});

  final String title;
  final bool cleared;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return PressableScale(
      onTap: onTap,
      child: Semantics(
        button: true,
        label: title,
        excludeSemantics: true,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                DesignTokens.earGold.withValues(alpha: p.dark ? 0.22 : 0.18),
                DesignTokens.streakOrange.withValues(alpha: p.dark ? 0.12 : 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadii.md),
            border: Border.all(color: DesignTokens.earGold, width: 1.4),
          ),
          child: Row(
            children: [
              const Text('👑', style: TextStyle(fontSize: 30)),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: t.titleMedium?.copyWith(color: p.gold, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      cleared ? '✓ ${EarStrings.bossClearedBadge}' : EarStrings.bossSubtitle,
                      style: t.bodySmall?.copyWith(
                        color: cleared ? p.success : p.textSecondary,
                        fontWeight: cleared ? FontWeight.w800 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded, color: p.gold, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
