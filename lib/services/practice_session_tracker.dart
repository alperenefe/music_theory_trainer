/// Oturum içi doğru / toplam (ZIP «Puan: doğru/tamamlanan»).
final class PracticeSessionTracker {
  int correct = 0;
  int total = 0;

  void record(bool ok) {
    total++;
    if (ok) {
      correct++;
    }
  }

  String label() => 'Puan: $correct/$total';
}
