import 'package:flutter/material.dart';

import '../../models/ear_curriculum.dart';
import '../../models/ear_exercise_kind.dart';
import '../../services/practice_prefs_repository.dart';
import 'ear_quiz_screen.dart';

/// Aralık tanıma egzersizi.
///
/// Geriye dönük uyumluluk için korunur; tüm mantık [EarQuizScreen]'dedir.
final class AuralIntervalScreen extends StatelessWidget {
  const AuralIntervalScreen({
    super.key,
    required this.prefsRepo,
    this.weekNumber = 1,
    this.targetQuestionCount = 10,
  });

  final PracticePrefsRepository prefsRepo;
  final int weekNumber;
  final int targetQuestionCount;

  @override
  Widget build(BuildContext context) => EarQuizScreen(
        prefsRepo: prefsRepo,
        week: earWeekByNumber(weekNumber),
        kinds: const [EarExerciseKind.intervalBlind],
        questionCount: targetQuestionCount,
      );
}
