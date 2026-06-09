import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_attempt.dart';
import '../../services/practice_streak.dart';
import '../../services/stats_summary.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../../screens/stats_screen.dart';
import '../cards/soft_card.dart';
import '../motion/pressable_scale.dart';
import '../stats/accuracy_progress_bar.dart';

/// Günlük seri + genel doğruluk (ZIP ana sayfa şeridi).
final class HomeStatsBanner extends StatelessWidget {
  const HomeStatsBanner({
    super.key,
    required this.attempts,
  });

  final List<PracticeAttempt> attempts;

  Future<void> _openStats(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const StatsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final streak = PracticeStreak.currentStreak(attempts);
    final summary = summarizeAttempts(attempts);
    final accPct = (summary.accuracy * 100).round();
    return PressableScale(
      onTap: () => _openStats(context),
      child: SoftCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_fire_department_rounded,
                color: streak > 0
                    ? DesignTokens.streakOrange
                    : DesignTokens.slate600,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  streak > 0
                      ? AppStrings.homeStreakDays(streak)
                      : AppStrings.homeStreakNone,
                  style: t.titleSmall?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '${summary.total} ${AppStrings.attempts.toLowerCase()}',
                style: t.labelSmall?.copyWith(color: DesignTokens.slate500),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Text(
                  AppStrings.homeGlobalAccuracy,
                  style: t.labelSmall?.copyWith(
                    color: DesignTokens.slate500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$accPct%',
                style: t.labelMedium?.copyWith(
                  color: DesignTokens.green400,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          AccuracyProgressBar(
            accuracy: summary.total == 0 ? 0 : summary.accuracy,
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                AppStrings.statsTitle,
                style: t.labelSmall?.copyWith(
                  color: DesignTokens.slate500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: DesignTokens.slate500,
              ),
            ],
          ),
        ],
      ),
    ),
    )
        .animate()
        .fadeIn(duration: AppMotion.medium, curve: AppMotion.curve)
        .slideY(begin: 0.05, end: 0, duration: AppMotion.medium, curve: AppMotion.curve);
  }
}
