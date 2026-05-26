import 'package:flutter/material.dart';

import '../../l10n/app_strings.dart';
import '../../models/practice_attempt.dart';
import '../../services/practice_streak.dart';
import '../../services/stats_summary.dart';
import '../../theme/app_spacing.dart';
import '../../theme/design_tokens.dart';
import '../cards/soft_card.dart';

/// Günlük seri + genel doğruluk (ZIP ana sayfa şeridi).
final class HomeStatsBanner extends StatelessWidget {
  const HomeStatsBanner({
    super.key,
    required this.attempts,
  });

  final List<PracticeAttempt> attempts;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final streak = PracticeStreak.currentStreak(attempts);
    final summary = summarizeAttempts(attempts);
    final accPct = (summary.accuracy * 100).round();
    return SoftCard(
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
                    ? const Color(0xFFF97316)
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
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: summary.total == 0 ? 0 : summary.accuracy,
              minHeight: 8,
              backgroundColor: DesignTokens.slate800,
              color: DesignTokens.green400,
            ),
          ),
        ],
      ),
    );
  }
}
