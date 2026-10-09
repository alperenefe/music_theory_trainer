import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/practice_attempt.dart';
import '../services/goal_period_attempts.dart';
import '../services/goal_progress_snapshot.dart';
import '../services/practice_prefs_repository.dart';
import '../services/stats_repository.dart';
import '../theme/app_spacing.dart';
import '../screens/stats_screen.dart';
import '../widgets/background/mesh_gradient_backdrop.dart';
import '../widgets/exercise/exercise_screen_top_bar.dart';
import '../widgets/exercise/exercise_landing_preview.dart';
import '../widgets/home/activity_goal_progress_strip.dart';
import '../widgets/loading/home_list_skeleton.dart';
import '../widgets/stats/exercise_landing_stats_section.dart';

/// Egzersiz öncesi: önizleme + hedef; Başla sabit altta.
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
    this.extraContent,
  });

  final String title;
  final String description;
  final String exerciseId;
  final String? goalKind;
  final bool guitarStyleLabels;
  final PracticePrefsRepository prefsRepo;
  final Widget Function() buildPractice;

  /// Landing içeriğine eklenecek isteğe bağlı widget (örn. müfredat kartı).
  final Widget? extraContent;

  @override
  State<ExerciseLandingScreen> createState() => _ExerciseLandingScreenState();
}

final class _ExerciseLandingScreenState extends State<ExerciseLandingScreen> {
  final _statsRepo = StatsRepository();
  var _loading = true;
  var _rows = <PracticeAttempt>[];
  GoalProgressSnapshot? _goalProgress;
  var _goalPeriodActive = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final prefs = await widget.prefsRepo.load();
    final all = await _statsRepo.load();
    GoalProgressSnapshot? goal;
    final gk = widget.goalKind;
    final activeGoal = gk != null ? prefs.goalForKind(gk) : null;
    if (gk != null) {
      goal = GoalProgressSnapshot.forKind(kind: gk, prefs: prefs, all: all);
    }
    final rows = GoalPeriodAttempts.forExercise(
      all: all,
      exerciseId: widget.exerciseId,
      goal: activeGoal,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _rows = rows;
      _goalProgress = goal;
      _goalPeriodActive = activeGoal?.enabled == true;
      _loading = false;
    });
  }

  Future<void> _openExerciseStats() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => StatsScreen(
          initialExerciseFilter: widget.exerciseId,
        ),
      ),
    );
    if (mounted) {
      await _refresh();
    }
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
          child: _loading
              ? const HomeListSkeleton()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ExerciseScreenTopBar(
                      title: widget.title,
                      subtitle: widget.description,
                    ),
                    Expanded(
                      child: ListView(
                        padding: AppSpacing.screenH.copyWith(
                          top: AppSpacing.sm,
                          bottom: AppSpacing.sm,
                        ),
                        physics: const BouncingScrollPhysics(),
                        children: [
                          ExerciseLandingPreview(
                            goalKind: widget.goalKind,
                            compact: true,
                          ),
                          if (widget.extraContent != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            widget.extraContent!,
                          ],
                          if (_goalProgress != null && _rows.isEmpty) ...[
                            const SizedBox(height: AppSpacing.sm),
                            ActivityGoalProgressStrip(
                              snapshot: _goalProgress!,
                              variant: GoalProgressVariant.landingDual,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sm),
                          ExerciseLandingStatsSection(
                            rows: _rows,
                            goalPeriodActive: _goalPeriodActive,
                            onOpenStats: _openExerciseStats,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: AppSpacing.screenH.copyWith(
                        bottom: AppSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: _startPractice,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(AppStrings.start),
                          ),
                          if (_rows.isNotEmpty)
                            TextButton(
                              onPressed: _clearExerciseStats,
                              child: Text(AppStrings.clearExerciseStats),
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
