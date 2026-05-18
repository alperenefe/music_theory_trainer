import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/notation_pitch.dart';
import '../models/practice_attempt.dart';
import '../services/attempt_accuracy_series.dart';
import '../services/stats_repository.dart';
import '../services/stats_summary.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/cards/soft_card.dart';
import '../widgets/loading/home_list_skeleton.dart';
import '../widgets/stats/attempt_sparkline.dart';
import '../widgets/text/section_header.dart';

final class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

final class _StatsScreenState extends State<StatsScreen> {
  final _repo = StatsRepository();
  late Future<List<PracticeAttempt>> _future;

  @override
  void initState() {
    super.initState();
    _future = _repo.load();
  }

  void _refresh() {
    setState(() {
      _future = _repo.load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: FutureBuilder<List<PracticeAttempt>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting &&
                  !snap.hasData) {
                return const HomeListSkeleton();
              }
              if (snap.hasError) {
                return Center(
                  child: Padding(
                    padding: AppSpacing.screenHV,
                    child: Text(
                      '${snap.error}',
                      style: t.bodyMedium?.copyWith(
                        color: DesignTokens.rose400,
                      ),
                    ),
                  ),
                );
              }
              final rows = snap.data ?? [];
              final pool = NotationPitch.trainingPool();
              final s = summarizeAttempts(rows);
              final series = attemptAccuracySeries(rows);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: AppSpacing.screenH.copyWith(top: AppSpacing.sm),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: DesignTokens.slate200,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            AppStrings.statsTitle,
                            style: t.titleLarge?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: AppSpacing.screenHV,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SectionHeader(
                          title: AppStrings.statsTitle,
                          subtitle: AppStrings.statsDesc,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        SoftCard(
                          child: s.total == 0
                              ? Column(
                                  children: [
                                    Icon(
                                      Icons.insights_outlined,
                                      size: 48,
                                      color: DesignTokens.slate500,
                                    ),
                                    const SizedBox(height: AppSpacing.md),
                                    Text(
                                      AppStrings.noData,
                                      textAlign: TextAlign.center,
                                      style: t.titleSmall?.copyWith(
                                        color: DesignTokens.slate300,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      AppStrings.emptyStateHint,
                                      textAlign: TextAlign.center,
                                      style: t.bodyMedium?.copyWith(
                                        color: DesignTokens.slate400,
                                        height: 1.45,
                                      ),
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _metricRow(
                                      context,
                                      AppStrings.attempts,
                                      '${s.total}',
                                    ),
                                    _metricRow(
                                      context,
                                      AppStrings.accuracy,
                                      '${(s.accuracy * 100).round()}%',
                                    ),
                                    _metricRow(
                                      context,
                                      AppStrings.avgTime,
                                      s.avgLatencyMs == null
                                          ? '—'
                                          : '${s.avgLatencyMs} ms',
                                    ),
                                    if (series.length > 1) ...[
                                      const SizedBox(height: AppSpacing.md),
                                      Text(
                                        AppStrings.statsActivity,
                                        style: t.labelLarge?.copyWith(
                                          color: DesignTokens.slate300,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      AttemptSparkline(series: series),
                                    ],
                                  ],
                                ),
                        ),
                        if (s.midiStats.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            AppStrings.perMidi,
                            style: t.titleSmall?.copyWith(
                              color: DesignTokens.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ...s.midiStats.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: RepaintBoundary(
                                child: SoftCard(
                                  padding: AppSpacing.cardPadDense,
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          NotationPitch.displayForMidi(
                                            m.midi,
                                            pool,
                                          ),
                                          style: t.bodyMedium?.copyWith(
                                            color: DesignTokens.white,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${m.correct}/${m.total} · ${m.avgMs} ms',
                                        style: t.labelMedium?.copyWith(
                                          color: DesignTokens.slate400,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: () async {
                            await _repo.clear();
                            _refresh();
                          },
                          child: Text(AppStrings.clearStats),
                        ),
                      ],
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

  Widget _metricRow(BuildContext context, String k, String v) {
    final t = Theme.of(context).textTheme;
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
