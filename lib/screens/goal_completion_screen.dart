import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../l10n/app_strings.dart';
import '../models/goal_completion_report.dart';
import '../utils/stats_midi_label.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/feedback/celebration_burst.dart';
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
              const CelebrationBurst(),
              const SizedBox(height: AppSpacing.sm),
              // Kupa ikonu artık düz bir ikon değil, kutlama vurgusunu
              // taşıyan yumuşak parlamalı bir rozet içinde.
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DesignTokens.green400.withValues(alpha: 0.14),
                  boxShadow: [
                    BoxShadow(
                      color: DesignTokens.green400.withValues(alpha: 0.35),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 56,
                  color: DesignTokens.green400,
                ),
              )
                  .animate()
                  .fadeIn(delay: 120.ms)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1, 1),
                    duration: 420.ms,
                    curve: Curves.easeOutBack,
                  )
                  .slideY(begin: 0.15, end: 0, duration: 400.ms),
              const SizedBox(height: AppSpacing.lg),
              // Hero istatistik: doğruluk oranı, her şeyden önce göze
              // çarpan büyük bir sayı olarak — geri kalanı destek detayı.
              Text(
                '${(s.accuracy * 100).round()}%',
                textAlign: TextAlign.center,
                style: t.displaySmall?.copyWith(
                  color: DesignTokens.green400,
                  fontWeight: FontWeight.w900,
                  fontSize: 56,
                ),
              ).animate().fadeIn(delay: 200.ms).scale(
                    begin: const Offset(0.85, 0.85),
                    end: const Offset(1, 1),
                    duration: 380.ms,
                    curve: Curves.easeOutBack,
                  ),
              Text(
                AppStrings.accuracy,
                textAlign: TextAlign.center,
                style: t.labelLarge?.copyWith(
                  color: DesignTokens.slate400,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SoftCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Doğruluk artık yukarıda hero istatistik olarak
                    // gösteriliyor, burada tekrarlanmıyor.
                    _row(t, AppStrings.attempts, '${s.total}'),
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
