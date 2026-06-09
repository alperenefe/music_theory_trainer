import '../models/practice_attempt.dart';

/// D = doğru, Y = yanlış (hedef seçici ve istatistikte ortak gösterim).
String outcomeSymbol(bool correct) => correct ? 'D' : 'Y';

String formatOutcomeChain(Iterable<bool> outcomes) =>
    outcomes.map(outcomeSymbol).join(' ');

List<bool> recentOutcomes(
  List<PracticeAttempt> rows, {
  int max = 24,
}) {
  if (rows.isEmpty) {
    return const [];
  }
  final slice =
      rows.length <= max ? rows : rows.sublist(rows.length - max);
  return slice.map((r) => r.correct).toList();
}

List<bool> outcomesForMidi(
  List<PracticeAttempt> rows,
  int midi, {
  int max = 16,
}) {
  final matching = <PracticeAttempt>[];
  for (final r in rows) {
    if (r.midi == midi) {
      matching.add(r);
    }
  }
  if (matching.isEmpty) {
    return const [];
  }
  final slice = matching.length <= max
      ? matching
      : matching.sublist(matching.length - max);
  return slice.map((r) => r.correct).toList();
}
