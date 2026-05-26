import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_strings.dart';
import '../services/goal_tracker.dart';
import '../utils/stats_midi_label.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/text/section_header.dart';

final class GoalCompletionScreen extends StatelessWidget {
  const GoalCompletionScreen({super.key, required this.report});

  final GoalCompletionReport report;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final s = report.summary;
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: ListView(
            padding: AppSpacing.screenHV,
            children: [
              SectionHeader(
                title: AppStrings.goalCompletedTitle,
                subtitle:
                    '${report.goalTitle} · ${report.target} ${AppStrings.goalCompletedTarget}',
              )
                  .animate()
                  .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                  .scale(
                    begin: const Offset(0.92, 0.92),
                    end: const Offset(1, 1),
                    duration: 450.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: AppSpacing.md),
              Icon(
                Icons.emoji_events_rounded,
                size: 56,
                color: DesignTokens.green400,
              )
                  .animate()
                  .fadeIn(delay: 120.ms)
                  .slideY(begin: 0.15, end: 0, duration: 400.ms),
              const SizedBox(height: AppSpacing.md),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _row(t, AppStrings.attempts, '${s.total}'),
                    _row(
                      t,
                      AppStrings.accuracy,
                      '${(s.accuracy * 100).round()}%',
                    ),
                    _row(
                      t,
                      AppStrings.avgTime,
                      s.avgLatencyMs == null ? '—' : '${s.avgLatencyMs} ms',
                    ),
                    _row(
                      t,
                      AppStrings.goalMedian,
                      report.medianLatencyMs == null
                          ? '—'
                          : '${report.medianLatencyMs} ms',
                    ),
                    _row(t, AppStrings.goalWrong, '${report.totalWrong}'),
                    _row(
                      t,
                      AppStrings.goalPracticeTime,
                      '${(report.totalThinkingMs / 1000).toStringAsFixed(1)} s (${report.totalThinkingMs} ms)',
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.04, end: 0),
              if (s.midiStats.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.goalPerMidi,
                  style: t.titleSmall?.copyWith(
                    color: DesignTokens.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                ...s.midiStats.map(
                  (m) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: SoftCard(
                      padding: AppSpacing.cardPadDense,
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              StatsMidiLabel.forMidi(
                                m.midi,
                                guitarStyle: false,
                              ),
                              style: t.bodyMedium?.copyWith(
                                color: DesignTokens.white,
                              ),
                            ),
                          ),
                          Text(
                            '${(m.accuracy * 100).round()}% · '
                            '${m.correct}/${m.total} · ${m.avgMs} ms',
                            style: t.labelMedium?.copyWith(
                              color: DesignTokens.slate400,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppStrings.goalClose),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(TextTheme t, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Text(
              k,
              style: t.bodyMedium?.copyWith(color: DesignTokens.slate400),
            ),
          ),
          Text(
            v,
            style: t.titleMedium?.copyWith(
              color: DesignTokens.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
