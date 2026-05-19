import '../models/practice_attempt.dart';

abstract final class PracticeHistory {
  static List<PracticeAttempt> forExercise(
    List<PracticeAttempt> all,
    String exercise,
  ) =>
      all.where((e) => e.exercise == exercise).toList();
}
