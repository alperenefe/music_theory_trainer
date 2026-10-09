import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_curriculum.dart';
import '../../models/ear_session_result.dart';
import '../../services/ear_session_recorder.dart';
import '../../services/practice_prefs_repository.dart';
import '../../services/weak_spot_analyzer.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../widgets/ear/ear_layout.dart';
import '../../widgets/ear/ear_palette.dart';
import '../../widgets/ear/gate_criteria_list.dart';
import '../../widgets/feedback/celebration_burst.dart';
import 'weekly_reflection_sheet.dart';

/// Tur sonu ekranı: büyük doğruluk halkası, istatistikler, bu turun zayıf
/// noktaları ve hafta barajına ilerleme. Baraj eşiği her zaman haftanın
/// gerçek [MasteryGate] değerinden gelir (sabit %80 değil).
final class EarSessionSummary extends StatelessWidget {
  const EarSessionSummary({
    super.key,
    required this.result,
    required this.outcome,
    required this.week,
    required this.latenciesMs,
    required this.bestCombo,
    required this.heartsLeft,
    required this.onPlayAgain,
    required this.onDone,
    required this.prefsRepo,
  });

  final EarSessionResult result;

  /// Kayıt başarısız olduysa null (yine de tur sonucu gösterilir).
  final EarSessionOutcome? outcome;
  final EarWeek week;
  final List<int> latenciesMs;
  final int bestCombo;
  final int? heartsLeft;
  final VoidCallback onPlayAgain;
  final VoidCallback onDone;
  final PracticePrefsRepository prefsRepo;

  bool get _isBoss => result.mode == EarSessionMode.boss;
  bool get _bossWon => _isBoss && (heartsLeft ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    final pct = (result.accuracy * 100).round();
    final thresholdPct = (week.gate.accuracyThreshold * 100).round();
    final metThreshold = result.accuracy >= week.gate.accuracyThreshold;
    final reduced = AppMotion.reduced(context);

    final title = _isBoss
        ? (_bossWon ? EarStrings.bossWonTitle : EarStrings.bossLostTitle)
        : (pct == 100
            ? EarStrings.summaryPerfect
            : metThreshold
                ? EarStrings.summaryGreat
                : (pct >= 60 ? EarStrings.summaryKeepGoing : EarStrings.summaryTryAgain));

    final ringColor = metThreshold ? DesignTokens.earEmerald : DesignTokens.earAmber;
    final avgMs = latenciesMs.isEmpty
        ? null
        : latenciesMs.reduce((a, b) => a + b) / latenciesMs.length;
    final celebrate = (metThreshold && !_isBoss) || _bossWon ||
        (outcome?.weekJustCompleted ?? false);

    final weakSpots = const WeakSpotAnalyzer().topWeakSpots([result], n: 4);

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 760;
        final stats = _StatGrid(
          items: [
            (EarStrings.statCorrect, '${result.correctCount}/${result.totalQuestions}', Icons.check_circle_rounded),
            (EarStrings.statTime, EarStrings.minutesSeconds(result.durationSeconds), Icons.timer_outlined),
            (
              EarStrings.statAvgResponse,
              avgMs == null ? '—' : EarStrings.seconds(avgMs / 1000),
              Icons.bolt_rounded,
            ),
            (EarStrings.statBestCombo, '🔥 $bestCombo', Icons.local_fire_department_rounded),
          ],
        );

        final hero = Column(
          children: [
            if (celebrate) const CelebrationBurst() else const SizedBox(height: AppSpacing.lg),
            _AccuracyRing(value: result.accuracy, color: ringColor, label: '%$pct', reduced: reduced),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              textAlign: TextAlign.center,
              style: t.headlineSmall?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              result.mode.countsTowardGate
                  ? EarStrings.thresholdNote(thresholdPct)
                  : EarStrings.reviewNotCounted,
              textAlign: TextAlign.center,
              style: t.bodyMedium?.copyWith(color: p.textMuted),
            ),
          ],
        );

        final details = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (outcome?.unlockedWeek != null || (outcome?.weekJustCompleted ?? false))
              _Banner(
                icon: Icons.lock_open_rounded,
                color: DesignTokens.earEmerald,
                text: outcome!.unlockedWeek != null
                    ? '${EarStrings.weekCompletedBanner} ${EarStrings.weekUnlocked(outcome!.unlockedWeek!.weekNumber)}'
                    : EarStrings.weekCompletedBanner,
              ),
            stats,
            if (weakSpots.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle(EarStrings.sessionWeakTitle),
              Text(EarStrings.sessionWeakBody, style: t.bodySmall?.copyWith(color: p.textMuted)),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final w in weakSpots)
                    Chip(
                      avatar: const Icon(Icons.replay_rounded, size: 16, color: DesignTokens.earRose),
                      label: Text('${w.label} · ${w.errorCount}'),
                    ),
                ],
              ),
            ],
            if (outcome != null && result.mode.countsTowardGate) ...[
              const SizedBox(height: AppSpacing.lg),
              const _SectionTitle(EarStrings.gateProgressTitle),
              const SizedBox(height: AppSpacing.xs),
              GateCriteriaList(status: outcome!.gate),
            ],
          ],
        );

        final buttons = Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onPlayAgain,
                icon: const Icon(Icons.replay_rounded),
                label: const Text(EarStrings.playAgain),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton(
                onPressed: onDone,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: const Text(EarStrings.done),
              ),
            ),
          ],
        );

        final reflect = (outcome?.weekJustCompleted ?? false)
            ? Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: TextButton.icon(
                  onPressed: () => showWeeklyReflectionSheet(
                    context: context,
                    week: week,
                    progress: outcome!.after,
                    prefsRepo: prefsRepo,
                  ),
                  icon: const Icon(Icons.psychology_rounded),
                  label: const Text(EarStrings.reflectNow),
                ),
              )
            : const SizedBox.shrink();

        Widget body;
        if (wide) {
          body = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: hero),
              const SizedBox(width: AppSpacing.xxl),
              Expanded(flex: 5, child: details),
            ],
          );
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [hero, const SizedBox(height: AppSpacing.lg), details],
          );
        }
        if (!reduced) {
          body = body.animate().fadeIn(duration: 320.ms).slideY(begin: 0.03, end: 0);
        }

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EarLayout.pagePadding(c.maxWidth, maxWidth: wide ? 1040 : 640),
                child: body,
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                math.max(AppSpacing.md, (c.maxWidth - (wide ? 1040 : 640)) / 2),
                AppSpacing.xs,
                math.max(AppSpacing.md, (c.maxWidth - (wide ? 1040 : 640)) / 2),
                AppSpacing.md,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [buttons, reflect]),
            ),
          ],
        );
      },
    );
  }
}

final class _AccuracyRing extends StatelessWidget {
  const _AccuracyRing({
    required this.value,
    required this.color,
    required this.label,
    required this.reduced,
  });

  final double value;
  final Color color;
  final String label;
  final bool reduced;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    return SizedBox(
      width: 148,
      height: 148,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: reduced ? value : 0.0, end: value),
        duration: reduced ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 12,
                strokeCap: StrokeCap.round,
                backgroundColor: p.track,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text(
              label,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.items});

  final List<(String, String, IconData)> items;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 420 ? 4 : 2;
        const gap = AppSpacing.sm;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final (label, value, icon) in items)
              Container(
                width: w,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: p.surface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: p.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 18, color: p.textMuted),
                    const SizedBox(height: 6),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: t.titleMedium?.copyWith(color: p.textPrimary, fontWeight: FontWeight.w900),
                    ),
                    Text(label, style: t.labelSmall?.copyWith(color: p.textMuted)),
                  ],
                ),
              ),
          ],
        );
      },
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: EarPalette.of(context).textPrimary,
            fontWeight: FontWeight.w800,
          ),
    );
  }
}

final class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.color, required this.text});

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: p.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
