import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/practice_attempt.dart';
import '../services/attempt_accuracy_series.dart';
import '../services/stats_repository.dart';
import '../services/stats_summary.dart';
import '../theme/app_spacing.dart';
import '../theme/design_tokens.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/loading/home_list_skeleton.dart';
import '../widgets/stats/stats_midi_breakdown.dart';
import '../widgets/stats/stats_summary_card.dart';
import '../widgets/text/section_header.dart';

final class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

final class _StatsScreenState extends State<StatsScreen> {
  final _repo = StatsRepository();
  late Future<List<PracticeAttempt>> _future;
  String? _exerciseFilter; // null = tümü

  static const _filters = [
    (label: AppStrings.statsFilterAll, key: null),
    (label: AppStrings.statsFilterPlacement, key: AppStrings.exercisePlacement),
    (label: AppStrings.statsFilterMcq, key: AppStrings.exerciseMcq),
    (label: AppStrings.statsFilterInterval, key: AppStrings.exerciseInterval),
    (label: AppStrings.statsFilterScale, key: AppStrings.exerciseScale),
    (label: AppStrings.statsFilterChord, key: AppStrings.exerciseChord),
    (label: AppStrings.statsFilterGuitarMcq, key: AppStrings.exerciseGuitarMcq),
    (label: AppStrings.statsFilterGuitarFind, key: AppStrings.exerciseGuitarFind),
    (label: AppStrings.statsFilterGuitarPlay, key: AppStrings.exerciseGuitarPlay),
  ];

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

  Future<void> _confirmAndClear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.clearStatsConfirmTitle),
        content: Text(AppStrings.clearStatsConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(AppStrings.clearStatsConfirmOk),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.clear();
      _refresh();
    }
  }

  List<PracticeAttempt> _filtered(List<PracticeAttempt> rows) {
    if (_exerciseFilter == null) {
      return rows;
    }
    return rows.where((r) => r.exercise == _exerciseFilter).toList();
  }

  bool get _guitarStyleLabels {
    final f = _exerciseFilter;
    if (f == null) {
      return false;
    }
    return f == AppStrings.exerciseGuitarMcq ||
        f == AppStrings.exerciseGuitarFind ||
        f == AppStrings.exerciseGuitarPlay;
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
              final all = snap.data ?? [];
              final rows = _filtered(all);
              final summary = summarizeAttempts(rows);
              final series = attemptAccuracySeries(rows);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const ExerciseScreenTopBar(title: AppStrings.statsTitle),
                  // Filtre chips
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      separatorBuilder: (context, i) =>
                          const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (context, i) {
                        final f = _filters[i];
                        final selected = _exerciseFilter == f.key;
                        return FilterChip(
                          label: Text(f.label),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _exerciseFilter = f.key);
                          },
                          selectedColor:
                              DesignTokens.blue500.withValues(alpha: 0.25),
                          checkmarkColor: DesignTokens.blue500,
                          labelStyle: t.labelMedium?.copyWith(
                            color: selected
                                ? DesignTokens.white
                                : DesignTokens.slate300,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                          backgroundColor:
                              DesignTokens.slate900.withValues(alpha: 0.45),
                          side: BorderSide(
                            color: selected
                                ? DesignTokens.blue500.withValues(alpha: 0.6)
                                : DesignTokens.borderSubtle,
                          ),
                        );
                      },
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: AppSpacing.screenHV,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        SectionHeader(
                          title: AppStrings.statsTitle,
                          subtitle: _exerciseFilter == null
                              ? AppStrings.statsDesc
                              : _filters
                                  .firstWhere(
                                    (f) => f.key == _exerciseFilter,
                                  )
                                  .label,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        StatsSummaryCard(summary: summary, series: series),
                        const SizedBox(height: AppSpacing.lg),
                        StatsMidiBreakdown(
                          midiStats: summary.midiStats,
                          guitarStyleLabels: _guitarStyleLabels,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        OutlinedButton(
                          onPressed: _confirmAndClear,
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
}
