import 'practice_prefs_repository.dart';

abstract final class PracticeDay {
  /// `2026-10-09` biçiminde gün anahtarı (yerel saat).
  static String key(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Gitar çalışma süresini (ekran açık ve etkinken) güne yazar.
///
/// Günlük hedef bu süreyle ölçülür. Ekran açık unutulursa süre şişmesin diye
/// tek bir kayıt [maxChunk] ile sınırlıdır ve her yeni adımda sayaç sıfırlanır.
final class GuitarPracticeClock {
  GuitarPracticeClock({
    PracticePrefsRepository? repo,
    DateTime Function()? now,
    int Function()? elapsedMs,
  })  : _repo = repo ?? PracticePrefsRepository(),
        _now = now ?? DateTime.now,
        _elapsedMs = elapsedMs;

  static const maxChunk = Duration(minutes: 10);

  final PracticePrefsRepository _repo;
  final DateTime Function() _now;
  final int Function()? _elapsedMs;
  final _sw = Stopwatch();
  var _banked = 0;

  bool get running => _sw.isRunning;

  int get _total => _banked + (_elapsedMs?.call() ?? _sw.elapsedMilliseconds);

  void resume() {
    if (!_sw.isRunning) _sw.start();
  }

  void pause() {
    if (_sw.isRunning) _sw.stop();
  }

  /// Birikmiş süreyi bugüne yazar ve sayacı sıfırlar.
  Future<int> commit() async {
    pause();
    final ms = _total.clamp(0, maxChunk.inMilliseconds);
    _sw.reset();
    _banked = 0;
    if (ms < 2000) return 0;
    final prefs = await _repo.load();
    await _repo.save(prefs.withPracticeMs(PracticeDay.key(_now()), ms));
    return ms;
  }
}
