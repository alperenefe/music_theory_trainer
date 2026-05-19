import '../l10n/app_strings.dart';

abstract final class GoalKind {
  static const placement = 'placement';
  static const mcq = 'mcq';
  static const interval = 'interval';
  static const scale = 'scale';
  static const chord = 'chord';
  static const guitarMcq = 'gitar_mcq';
  static const guitarFind = 'gitar_bul';
  static const guitarPlay = 'gitar_cal';

  static String? title(String? kind) {
    if (kind == null) {
      return null;
    }
    return switch (kind) {
      placement => AppStrings.placementTitle,
      mcq => AppStrings.mcqTitle,
      interval => AppStrings.intervalTitle,
      scale => AppStrings.scaleTitle,
      chord => AppStrings.chordTitle,
      guitarMcq => AppStrings.guitarMcqTitle,
      guitarFind => AppStrings.guitarFindTitle,
      guitarPlay => AppStrings.guitarPlayTitle,
      _ => null,
    };
  }

  static String titleWithFallback(String kind) =>
      title(kind) ?? AppStrings.goalsTitle;

  static String? exerciseId(String kind) => switch (kind) {
        placement => AppStrings.exercisePlacement,
        mcq => AppStrings.exerciseMcq,
        interval => AppStrings.exerciseInterval,
        scale => AppStrings.exerciseScale,
        chord => AppStrings.exerciseChord,
        guitarMcq => AppStrings.exerciseGuitarMcq,
        guitarFind => AppStrings.exerciseGuitarFind,
        guitarPlay => AppStrings.exerciseGuitarPlay,
        _ => null,
      };

  static bool matchesExercise(String kind, String exercise) =>
      exerciseId(kind) == exercise;

  static const practiceKinds = [
    placement,
    mcq,
    interval,
    scale,
    chord,
    guitarMcq,
    guitarFind,
    guitarPlay,
  ];

  static String? kindForExercise(String exercise) {
    for (final k in practiceKinds) {
      if (exerciseId(k) == exercise) {
        return k;
      }
    }
    return null;
  }
}
