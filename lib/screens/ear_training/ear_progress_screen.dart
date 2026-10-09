import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../models/ear_exercise_kind.dart';
import '../../models/ear_session_result.dart';
import '../../models/weekly_progress.dart';
import '../../services/ear_curriculum_service.dart';
import '../../services/ear_question_factory.dart';
import '../../services/practice_prefs_repository.dart';
import '../../services/weak_spot_analyzer.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/background/mesh_gradient_backdrop.dart';
import '../../widgets/ear/accuracy_trend_chart.dart';
import '../../widgets/ear/ear_layout.dart';
import '../../widgets/ear/ear_palette.dart';
import '../../widgets/ear/interval_anchors_sheet.dart';
import '../../widgets/ear/practice_heatmap.dart';
import '../../widgets/ear/week_progress_ring.dart';
import 'ear_quiz_screen.dart';

final class EarProgressScreen extends StatefulWidget {
  const EarProgressScreen({
    super.key,
    required this.prefsRepo,
  });

  final PracticePrefsRepository prefsRepo;

  @override
  State<EarProgressScreen> createState() => _EarProgressScreenState();
}

final class _EarProgressScreenState extends State<EarProgressScreen> {
  static const _curriculum = EarCurriculumService();
  static const _analyzer = WeakSpotAnalyzer();
  static const _heatmapWeeks = 12;

  List<WeeklyProgress> _progressList = const [];
  List<EarSessionResult> _history = const [];
  Set<String> _practicedDays = const {};
  List<WeakSpot> _weakSpots = const [];
  List<SubtypeAccuracy> _subtypeAcc = const [];
  var _anchorCount = 0;
  var _streak = 0;
  var _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await widget.prefsRepo.load();
    if (!mounted) return;
    setState(() {
      _progressList = _curriculum.ensureProgressList(prefs.earWeekProgress);
      _history = prefs.earSessionHistory;
      // Seri hesabı ve ısı haritası tabanı earSessionHistory (60 kayıtla
      // sınırlı) yerine tüm haftalardaki activeDays'in birleşimini kullanır —
      // bu liste asla budanmaz, bu yüzden günde birden fazla seans yapan bir
      // kullanıcıda bile eski günler "çalışılmamış" gibi görünmez.
      _practicedDays = _curriculum.practicedDayKeys(_progressList);
      _streak = _curriculum.calculateStreak(_practicedDays);
      _weakSpots = _analyzer.topWeakSpots(_history, n: 5);
      _subtypeAcc = _analyzer.subtypeAccuracy(_history);
      _anchorCount = prefs.intervalAnchors.length;
      _loaded = true;
    });
  }

  Future<void> _practice(WeakSpot spot) async {
    final week = _curriculum.currentWeek(_progressList);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EarQuizScreen(
          prefsRepo: widget.prefsRepo,
          week: week,
          kinds: earKindsIntroducedBy(week.weekNumber),
          mode: EarSessionMode.review,
          targetSubtypes: [spot.subtype],
          questionCount: 8,
        ),
      ),
    );
    await _loadData();
  }

  Future<void> _editAnchors() async {
    final saved = await IntervalAnchorsSheet.show(context, widget.prefsRepo);
    if (saved != null && mounted) setState(() => _anchorCount = saved.length);
  }

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(EarStrings.progressTitle),
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
      ),
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: !_loaded
              ? const Center(child: CircularProgressIndicator())
              : LayoutBuilder(
                  builder: (context, c) {
                    final completedWeeks = _progressList.where((x) => x.isCompleted).length;
                    var q = 0;
                    var ok = 0;
                    for (final x in _progressList) {
                      q += x.totalQuestions;
                      ok += x.totalCorrect;
                    }
                    final overall = q == 0 ? 0 : (ok / q * 100).round();

                    return ListView(
                      padding: EarLayout.pagePadding(c.maxWidth),
                      children: [
                        _SummaryCard(
                          streak: _streak,
                          completedWeeks: completedWeeks,
                          overallPct: overall,
                          totalQuestions: q,
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _Title(EarStrings.trendTitle),
                        const SizedBox(height: 2),
                        Text(
                          EarStrings.trendSubtitle(_history.take(20).length),
                          style: t.bodySmall?.copyWith(color: p.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SectionCard(
                          child: AccuracyTrendChart(sessions: _history.take(20).toList()),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _Title(EarStrings.heatmapTitle),
                        const SizedBox(height: 2),
                        Text(
                          EarStrings.heatmapSubtitle(_heatmapWeeks * 7),
                          style: t.bodySmall?.copyWith(color: p.textMuted),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _SectionCard(
                          child: PracticeHeatmap(
                            sessions: _history,
                            practicedDays: _practicedDays,
                            weeks: _heatmapWeeks,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _Title(EarStrings.weakTitle),
                        const SizedBox(height: 2),
                        Text(EarStrings.weakBody, style: t.bodySmall?.copyWith(color: p.textMuted)),
                        const SizedBox(height: AppSpacing.sm),
                        if (_weakSpots.isEmpty)
                          const _EmptyBox(text: EarStrings.weakEmpty)
                        else
                          _WeakSpotList(
                            spots: _weakSpots,
                            onPractice: _practice,
                          ),
                        const SizedBox(height: AppSpacing.xl),
                        const _Title(EarStrings.subtypeAccTitle),
                        const SizedBox(height: 2),
                        Text(EarStrings.subtypeAccBody, style: t.bodySmall?.copyWith(color: p.textMuted)),
                        const SizedBox(height: AppSpacing.sm),
                        if (_subtypeAcc.isEmpty)
                          const _EmptyBox(text: EarStrings.subtypeAccEmpty)
                        else
                          _SectionCard(child: _SubtypeAccuracyList(items: _subtypeAcc)),
                        const SizedBox(height: AppSpacing.xl),
                        const _Title(EarStrings.anchorsTitle),
                        const SizedBox(height: 2),
                        Text(EarStrings.anchorsBody, style: t.bodySmall?.copyWith(color: p.textMuted)),
                        const SizedBox(height: AppSpacing.sm),
                        _SectionCard(
                          child: Row(
                            children: [
                              const Icon(Icons.library_music_rounded, color: DesignTokens.earGold),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(
                                  EarStrings.anchorsCount(_anchorCount),
                                  style: t.titleSmall?.copyWith(
                                    color: p.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: _editAnchors,
                                child: const Text(EarStrings.anchorsEdit),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const _Title(EarStrings.recentTitle),
                        const SizedBox(height: AppSpacing.sm),
                        if (_history.isEmpty)
                          const _EmptyBox(text: EarStrings.recentEmpty)
                        else
                          for (final s in _history.take(8)) _RecentTile(session: s),
                        const SizedBox(height: AppSpacing.xl),
                        const _Title(EarStrings.curriculumStatus),
                        const SizedBox(height: AppSpacing.sm),
                        for (final week in earCurriculumWeeks)
                          _WeekStatusTile(
                            week: week,
                            progress: _curriculum.progressForWeek(week.weekNumber, _progressList),
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

final class _Title extends StatelessWidget {
  const _Title(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: EarPalette.of(context).textPrimary,
              fontWeight: FontWeight.w900,
            ),
      );
}

/// Trend grafiği/takvim gibi görsel bölümler için ortak kart çerçevesi.
final class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: child,
    );
  }
}

final class _EmptyBox extends StatelessWidget {
  const _EmptyBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: p.border),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: p.textMuted),
      ),
    );
  }
}

final class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.streak,
    required this.completedWeeks,
    required this.overallPct,
    required this.totalQuestions,
  });

  final int streak;
  final int completedWeeks;
  final int overallPct;
  final int totalQuestions;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final total = earCurriculumWeeks.length;

    Widget stat(String value, String label, Color color) => Expanded(
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: t.headlineSmall?.copyWith(color: color, fontWeight: FontWeight.w900),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                textAlign: TextAlign.center,
                style: t.labelSmall?.copyWith(
                  color: p.textMuted,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: p.border),
        boxShadow: [BoxShadow(color: p.shadow, blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              stat('🔥 $streak', EarStrings.statStreak, DesignTokens.streakOrange),
              stat('$completedWeeks/$total', EarStrings.statWeeksDone, p.success),
              stat('%$overallPct', EarStrings.statOverall, p.info),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (completedWeeks / total).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: p.track,
              valueColor: const AlwaysStoppedAnimation(DesignTokens.earEmerald),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            EarStrings.totalSummary(totalQuestions, completedWeeks),
            style: t.bodySmall?.copyWith(color: p.textMuted),
          ),
        ],
      ),
    );
  }
}

final class _WeakSpotList extends StatelessWidget {
  const _WeakSpotList({required this.spots, required this.onPractice});

  final List<WeakSpot> spots;
  final void Function(WeakSpot) onPractice;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final maxErr = spots.map((s) => s.errorCount).fold<int>(1, (a, b) => a > b ? a : b);

    return Column(
      children: [
        for (final spot in spots)
          Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.xs),
            padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
            decoration: BoxDecoration(
              color: p.surface,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              border: Border.all(color: p.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              spot.label,
                              style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Text(
                            EarStrings.errorCount(spot.errorCount),
                            style: t.labelMedium?.copyWith(color: p.danger, fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: spot.errorCount / maxErr,
                          minHeight: 6,
                          backgroundColor: p.track,
                          valueColor: const AlwaysStoppedAnimation(DesignTokens.earRose),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                if (EarQuestionFactory.isKnownSubtype(spot.subtype))
                  TextButton(
                    onPressed: () => onPractice(spot),
                    child: const Text(EarStrings.practiceThis),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _SubtypeAccuracyList extends StatelessWidget {
  const _SubtypeAccuracyList({required this.items});

  final List<SubtypeAccuracy> items;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return Column(
      children: [
        for (final it in items)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        it.label,
                        style: t.bodyMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w700),
                      ),
                    ),
                    Text(
                      '%${(it.accuracy * 100).round()}',
                      style: t.titleSmall?.copyWith(
                        color: _color(it.accuracy),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: it.accuracy,
                    minHeight: 6,
                    backgroundColor: p.track,
                    valueColor: AlwaysStoppedAnimation(_color(it.accuracy)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  EarStrings.subtypeAccMeta(it.correct, it.attempts),
                  style: t.labelSmall?.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static Color _color(double acc) => acc < 0.7
      ? DesignTokens.earRose
      : (acc < 0.85 ? DesignTokens.earAmber : DesignTokens.earEmerald);
}

final class _RecentTile extends StatelessWidget {
  const _RecentTile({required this.session});

  final EarSessionResult session;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final pct = (session.accuracy * 100).round();
    final threshold = earWeekByNumber(session.weekNumber).gate.accuracyThreshold;
    final good = session.accuracy >= threshold;
    final d = session.completedAt;
    final date = '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: p.border),
      ),
      child: Row(
        children: [
          Text(session.kind.emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${session.kind.label} · ${EarStrings.modeLabel(session.mode.name)}',
                  style: t.titleSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${EarStrings.weekLabel(session.weekNumber)} · $date · '
                  '${session.correctCount}/${session.totalQuestions}',
                  style: t.bodySmall?.copyWith(color: p.textMuted),
                ),
              ],
            ),
          ),
          Text(
            '%$pct',
            style: t.titleMedium?.copyWith(
              color: good ? p.success : p.textSecondary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

final class _WeekStatusTile extends StatelessWidget {
  const _WeekStatusTile({required this.week, required this.progress});

  final EarWeek week;
  final WeeklyProgress progress;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final acc = (progress.gateAccuracy * 100).round();
    final line = progress.isCompleted
        ? EarStrings.weekDoneLine(acc, progress.totalQuestions)
        : (progress.isUnlocked
            ? EarStrings.weekActiveLine(acc, progress.totalQuestions, week.gate.minQuestions)
            : EarStrings.weekLockedLine);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: progress.isUnlocked ? p.surface : p.surfaceLocked,
        borderRadius: BorderRadius.circular(AppRadii.sm),
        border: Border.all(color: progress.isCompleted ? DesignTokens.earEmerald.withValues(alpha: 0.6) : p.border),
      ),
      child: Row(
        children: [
          WeekProgressRing(week: week, progress: progress, size: 40),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${EarStrings.weekLabel(week.weekNumber)}: ${week.title}',
                  style: t.titleSmall?.copyWith(
                    color: progress.isUnlocked ? p.textPrimary : p.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  line,
                  style: t.bodySmall?.copyWith(
                    color: progress.isCompleted ? p.success : p.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (progress.confidence != null)
            Tooltip(
              message: EarStrings.reflectionTitle,
              child: Text(
                '🧠 ${progress.confidence}/5',
                style: t.labelMedium?.copyWith(color: p.textSecondary, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}
