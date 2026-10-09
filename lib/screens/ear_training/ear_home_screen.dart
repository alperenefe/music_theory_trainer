import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../models/ear_session_result.dart';
import '../../models/weekly_progress.dart';
import '../../services/ear_curriculum_service.dart';
import '../../services/ear_question_factory.dart';
import '../../services/ear_srs_service.dart';
import '../../services/practice_prefs_repository.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/ear/ear_layout.dart';
import '../../widgets/ear/ear_palette.dart';
import '../../widgets/ear/week_progress_ring.dart';
import '../../widgets/motion/motion_entrance.dart';
import '../../widgets/motion/pressable_scale.dart';
import 'ear_progress_screen.dart';
import 'ear_quiz_screen.dart';
import 'ear_week_detail_screen.dart';

final class EarHomeScreen extends StatefulWidget {
  const EarHomeScreen({
    super.key,
    required this.prefsRepo,
  });

  final PracticePrefsRepository prefsRepo;

  @override
  State<EarHomeScreen> createState() => _EarHomeScreenState();
}

final class _EarHomeScreenState extends State<EarHomeScreen> {
  static const _curriculum = EarCurriculumService();
  final _srs = EarSrsService();

  List<WeeklyProgress> _progressList = const [];
  List<String> _dueKeys = const [];
  var _streak = 0;
  var _practicedToday = false;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await widget.prefsRepo.load();
    List<String> due;
    try {
      due = (await _srs.dueToday()).where(EarQuestionFactory.isKnownSubtype).toList();
    } catch (_) {
      due = const [];
    }
    if (!mounted) return;
    setState(() {
      _progressList = _curriculum.ensureProgressList(prefs.earWeekProgress);
      // earSessionHistory yerine tüm haftalardaki activeDays'in birleşimini
      // kullan — history 60 kayıtla sınırlı, activeDays asla budanmaz.
      final practicedDays = _curriculum.practicedDayKeys(_progressList);
      _streak = _curriculum.calculateStreak(practicedDays);
      _practicedToday = _curriculum.practicedToday(practicedDays);
      _dueKeys = due;
      _loaded = true;
    });
  }

  WeeklyProgress _progressOf(int weekNumber) =>
      _curriculum.progressForWeek(weekNumber, _progressList);

  Future<void> _push(Widget page) async {
    await Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => page));
    await _refresh();
  }

  void _openWeek(EarWeek week) {
    final progress = _progressOf(week.weekNumber);
    if (!progress.isUnlocked) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(EarStrings.weekLockedSnack(week.weekNumber)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return;
    }
    _push(EarWeekDetailScreen(week: week, progress: progress, prefsRepo: widget.prefsRepo));
  }

  void _startDaily(EarWeek week) {
    _push(
      EarQuizScreen(
        prefsRepo: widget.prefsRepo,
        week: week,
        kinds: earExpandKinds(week, week.exercises),
      ),
    );
  }

  void _startReview(EarWeek week) {
    if (_dueKeys.isEmpty) return;
    _push(
      EarQuizScreen(
        prefsRepo: widget.prefsRepo,
        week: week,
        kinds: earKindsIntroducedBy(week.weekNumber),
        mode: EarSessionMode.review,
        targetSubtypes: _dueKeys,
        questionCount: _dueKeys.length.clamp(5, 10),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(EarStrings.moduleTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        actions: [
          if (_loaded) _StreakChip(streak: _streak, active: _practicedToday),
          IconButton(
            tooltip: EarStrings.progressTooltip,
            icon: const Icon(Icons.insights_rounded),
            onPressed: () => _push(EarProgressScreen(prefsRepo: widget.prefsRepo)),
          ),
        ],
      ),
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, c) {
                    final activeWeek = _curriculum.currentWeek(_progressList);
                    final completed = _progressList.where((x) => x.isCompleted).length;
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EarLayout.pagePadding(c.maxWidth),
                        children: [
                          _DailyCard(
                            week: activeWeek,
                            doneToday: _practicedToday,
                            onStart: () => _startDaily(activeWeek),
                          ).entranceFadeSlide(context),
                          const SizedBox(height: AppSpacing.md),
                          _ReviewCard(
                            dueCount: _dueKeys.length,
                            onStart: () => _startReview(activeWeek),
                          ).entranceFadeSlide(context, delay: const Duration(milliseconds: 60)),
                          const SizedBox(height: AppSpacing.xl),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  EarStrings.roadmapTitle,
                                  style: t.titleLarge?.copyWith(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              Text(
                                '$completed / ${earCurriculumWeeks.length}',
                                style: t.labelLarge?.copyWith(
                                  color: p.textMuted,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          for (final week in earCurriculumWeeks)
                            _RoadmapItem(
                              week: week,
                              progress: _progressOf(week.weekNumber),
                              isActive: week.weekNumber == activeWeek.weekNumber &&
                                  !_progressOf(week.weekNumber).isCompleted,
                              isLast: week.weekNumber == earCurriculumWeeks.last.weekNumber,
                              onTap: () => _openWeek(week),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}

final class _StreakChip extends StatelessWidget {
  const _StreakChip({required this.streak, required this.active});

  final int streak;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final color = active ? DesignTokens.streakOrange : p.textMuted;
    return Tooltip(
      message: EarStrings.streakTooltip,
      child: Container(
        margin: const EdgeInsets.only(right: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(
          '${active ? '🔥' : '🕯️'} ${EarStrings.streakDays(streak)}',
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: active ? DesignTokens.streakOrange : p.textSecondary,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

final class _DailyCard extends StatelessWidget {
  const _DailyCard({required this.week, required this.doneToday, required this.onStart});

  final EarWeek week;
  final bool doneToday;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: [
          BoxShadow(
            color: DesignTokens.blue600.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: LayoutBuilder(
        builder: (context, c) {
          final stacked = c.maxWidth < 360;
          final text = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  EarStrings.dailyBadge(week.weekNumber),
                  style: t.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                week.title,
                style: t.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                doneToday ? EarStrings.dailyDone : EarStrings.dailyBody,
                style: t.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.85)),
              ),
            ],
          );
          final button = FilledButton.icon(
            onPressed: onStart,
            icon: Icon(doneToday ? Icons.replay_rounded : Icons.play_arrow_rounded),
            label: Text(doneToday ? EarStrings.oneMore : EarStrings.startNow),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DesignTokens.blue600,
              textStyle: t.titleSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
          );
          if (stacked) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [text, const SizedBox(height: AppSpacing.md), button],
            );
          }
          return Row(
            children: [
              Expanded(child: text),
              const SizedBox(width: AppSpacing.md),
              button,
            ],
          );
        },
      ),
    );
  }
}

final class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.dueCount, required this.onStart});

  final int dueCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final hasDue = dueCount > 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(
          color: hasDue ? DesignTokens.violet500.withValues(alpha: 0.7) : p.border,
          width: hasDue ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: DesignTokens.violet500.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text('🧠', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasDue ? EarStrings.reviewDue(dueCount) : EarStrings.reviewNone,
                  style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(EarStrings.reviewBody, style: t.bodySmall?.copyWith(color: p.textMuted)),
              ],
            ),
          ),
          if (hasDue) ...[
            const SizedBox(width: AppSpacing.xs),
            FilledButton.tonal(
              onPressed: onStart,
              child: const Text(EarStrings.reviewStart),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dikey zaman çizelgesi düğümü: halka + bağlantı çizgisi + hafta kartı.
final class _RoadmapItem extends StatelessWidget {
  const _RoadmapItem({
    required this.week,
    required this.progress,
    required this.isActive,
    required this.isLast,
    required this.onTap,
  });

  final EarWeek week;
  final WeeklyProgress progress;
  final bool isActive;
  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final done = progress.isCompleted;
    final unlocked = progress.isUnlocked;
    final lineColor = done ? DesignTokens.earEmerald.withValues(alpha: 0.6) : p.track;

    final statusText = done
        ? EarStrings.completed
        : (unlocked ? EarStrings.active : EarStrings.locked);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 60,
            child: Column(
              children: [
                WeekProgressRing(week: week, progress: progress, size: 52, highlight: isActive),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 4,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: lineColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: PressableScale(
                onTap: onTap,
                haptic: unlocked,
                child: Semantics(
                  button: true,
                  label: '${EarStrings.weekLabel(week.weekNumber)}: ${week.title}. $statusText',
                  excludeSemantics: true,
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: AppMotion.dur(context, AppMotion.fast),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: unlocked ? p.surface : p.surfaceLocked,
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      border: Border.all(
                        color: isActive
                            ? DesignTokens.blue500
                            : (done ? DesignTokens.earEmerald.withValues(alpha: 0.7) : p.border),
                        width: isActive ? 2 : 1,
                      ),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: DesignTokens.blue500.withValues(alpha: 0.25),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              EarStrings.weekLabel(week.weekNumber),
                              style: t.labelMedium?.copyWith(
                                color: done ? p.success : (unlocked ? p.info : p.textMuted),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            if (isActive) const _Pill(text: EarStrings.nowBadge, color: DesignTokens.blue500),
                            if (week.isConsolidation)
                              const _Pill(text: EarStrings.consolidationBadge, color: DesignTokens.earGold),
                            if (progress.bossCleared) const _Pill(text: '👑', color: DesignTokens.earGold),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          week.title,
                          style: t.titleSmall?.copyWith(
                            color: unlocked ? p.textPrimary : p.textMuted,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          week.subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: t.bodySmall?.copyWith(color: p.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: EarPalette.of(context).textPrimary,
              fontSize: 9.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.4,
            ),
      ),
    );
  }
}
