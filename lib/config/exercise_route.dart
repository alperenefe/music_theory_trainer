import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../screens/exercise_landing_screen.dart';
import 'home_route_catalog.dart';

bool guitarStyleStatsFor(String exerciseId) =>
    exerciseId == AppStrings.exerciseGuitarMcq ||
    exerciseId == AppStrings.exerciseGuitarFind ||
    exerciseId == AppStrings.exerciseGuitarPlay;

/// Pratik egzersizini istatistik + Başla girişi ile sarar.
Widget exerciseLanding({
  required HomeNavDeps deps,
  required String title,
  required String description,
  required String exerciseId,
  required String? goalKind,
  required Widget Function(HomeNavDeps d) buildPractice,
}) {
  return ExerciseLandingScreen(
    title: title,
    description: description,
    exerciseId: exerciseId,
    goalKind: goalKind,
    guitarStyleLabels: guitarStyleStatsFor(exerciseId),
    prefsRepo: deps.prefsRepo,
    buildPractice: () => buildPractice(deps),
  );
}
