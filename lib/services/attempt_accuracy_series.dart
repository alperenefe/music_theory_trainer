import '../models/practice_attempt.dart';

List<double> attemptAccuracySeries(
  List<PracticeAttempt> rows, {
  int maxPoints = 40,
  int window = 5,
}) {
  if (rows.isEmpty) {
    return const [];
  }
  final sorted = [...rows]..sort((a, b) => a.atMillis.compareTo(b.atMillis));
  final tail = sorted.length > maxPoints
      ? sorted.sublist(sorted.length - maxPoints)
      : sorted;
  final out = <double>[];
  for (var i = 0; i < tail.length; i++) {
    final lo = (i - window + 1).clamp(0, i);
    var c = 0;
    var t = 0;
    for (var j = lo; j <= i; j++) {
      t++;
      if (tail[j].correct) {
        c++;
      }
    }
    if (t > 0) {
      out.add(c / t);
    }
  }
  return out;
}
