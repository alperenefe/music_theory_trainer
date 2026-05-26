import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/practice_attempt.dart';
import '../services/goal_progress_snapshot.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../theme/app_spacing.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/exercise/exercise_stats_panel.dart';
import '../widgets/home/activity_goal_progress_strip.dart';
import '../widgets/loading/home_list_skeleton.dart';
import '../widgets/text/section_header.dart';

/// Egzersiz öncesi: hedef ilerlemesi, son 500 istatistik, Başla.
final class ExerciseLandingScreen extends StatefulWidget {
  const ExerciseLandingScreen({
    super.key,
    required this.title,
    required this.description,
    required this.exerciseId,
    required this.goalKind,
    required this.guitarStyleLabels,
    required this.prefsRepo,
    required this.buildPractice,
  });

  final String title;
  final String description;
  final String exerciseId;
  final String? goalKind;
  final bool guitarStyleLabels;
  final PracticePrefsRepository prefsRepo;
  final Widget Function() buildPractice;

  @override
  State<ExerciseLandingScreen> createState() => _ExerciseLandingScreenState();
}

final class _ExerciseLandingScreenState extends State<ExerciseLandingScreen> {
  final _statsRepo = StatsRepository();
  var _loading = true;
  var _rows = <PracticeAttempt>[];
  GoalProgressSnapshot? _goalProgress;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await widget.prefsRepo.load();
    final rows = await _statsRepo.recentForExercise(widget.exerciseId);
    GoalProgressSnapshot? goal;
    final gk = widget.goalKind;
    if (gk != null) {
      final all = await _statsRepo.load();
      goal = GoalProgressSnapshot.forKind(kind: gk, prefs: prefs, all: all);
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _rows = rows;
      _goalProgress = goal;
      _loading = false;
    });
  }

  Future<void> _startPractice() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => widget.buildPractice()),
    );
    if (mounted) {
      await _refresh();
    }
  }

  Future<void> _clearExerciseStats() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.clearExerciseStatsTitle),
        content: Text(AppStrings.clearExerciseStatsBody),
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
      await _statsRepo.clearExercise(widget.exerciseId);
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MeshGradientBackdrop(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ExerciseScreenTopBar(title: widget.title),
              Expanded(
                child: _loading
                    ? const HomeListSkeleton()
                    : ListView(
                        padding: AppSpacing.screenHV,
                        physics: const BouncingScrollPhysics(),
                        children: [
                          SectionHeader(
                            title: widget.title,
                            subtitle: widget.description,
                          ),
                          if (_goalProgress != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            ActivityGoalProgressStrip(
                              snapshot: _goalProgress!,
                              variant: GoalProgressVariant.landingDual,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton.icon(
                            onPressed: _startPractice,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(AppStrings.start),
                          ),
                          if (_rows.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton(
                              onPressed: _clearExerciseStats,
                              child: Text(AppStrings.clearExerciseStats),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          ExerciseStatsPanel(
                            rows: _rows,
                            guitarStyleLabels: widget.guitarStyleLabels,
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
