import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_session_result.dart';
import '../../models/weekly_progress.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// GitHub tarzı haftalık pratik takvimi: hangi günler çalışıldığını,
/// yoğunluğa göre renklenen küçük karelerle gösterir.
///
/// Sayısal "🔥 N gün" rozetiyle aynı [WeeklyProgress.dayKey] gün-anahtarını
/// kullanır, böylece seri hesabıyla tutarlıdır.
final class PracticeHeatmap extends StatelessWidget {
  const PracticeHeatmap({
    super.key,
    required this.sessions,
    this.practicedDays = const {},
    this.weeks = 12,
  });

  final List<EarSessionResult> sessions;

  /// [sessions] `earSessionHistory`den gelir ve 60 kayıtla sınırlıdır; günde
  /// birden fazla seans yapan bir kullanıcıda eski günlerin TÜM seansları
  /// listeden düşebilir. Bu yüzden gün başına gerçek sayı (renk yoğunluğu)
  /// [sessions]'dan gelse de, bir günün "hiç çalışılmadı" (boş/gri hücre)
  /// mı yoksa "çalışıldı ama artık geçmişte kaydı yok" mu olduğunu ayırt
  /// etmek için [practicedDays] (asla budanmayan [WeeklyProgress.activeDays]
  /// birleşimi) bir taban/floor olarak kullanılır — [sessions]'da kaydı
  /// kalmamış ama [practicedDays]'de olan bir gün, 0 yerine en az 1 sayılır.
  final Set<String> practicedDays;
  final int weeks;

  static const _cell = 13.0;
  static const _gap = 3.0;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final counts = <String, int>{};
    for (final s in sessions) {
      final key = WeeklyProgress.dayKey(s.completedAt);
      counts[key] = (counts[key] ?? 0) + 1;
    }

    // Pazartesiye hizalanmış başlangıç günü, tam hafta sütunları için.
    var start = today.subtract(Duration(days: weeks * 7 - 1));
    start = start.subtract(Duration(days: start.weekday - 1));
    final totalWeeks = (today.difference(start).inDays ~/ 7) + 1;

    Color colorFor(int count) {
      if (count <= 0) return p.track;
      if (count == 1) return DesignTokens.streakOrange.withValues(alpha: 0.42);
      if (count == 2) return DesignTokens.streakOrange.withValues(alpha: 0.7);
      return DesignTokens.streakOrange;
    }

    final columns = <Widget>[
      for (var wk = 0; wk < totalWeeks; wk++)
        Padding(
          padding: const EdgeInsets.only(right: _gap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var d = 0; d < 7; d++)
                Padding(
                  padding: const EdgeInsets.only(bottom: _gap),
                  child: Builder(
                    builder: (context) {
                      final day = start.add(Duration(days: wk * 7 + d));
                      final isFuture = day.isAfter(today);
                      final key = WeeklyProgress.dayKey(day);
                      final rawCount = counts[key] ?? 0;
                      final count = rawCount > 0
                          ? rawCount
                          : (practicedDays.contains(key) ? 1 : 0);
                      return Tooltip(
                        message: isFuture
                            ? ''
                            : '${day.day.toString().padLeft(2, '0')}.'
                                '${day.month.toString().padLeft(2, '0')} · $count',
                        child: Container(
                          width: _cell,
                          height: _cell,
                          decoration: BoxDecoration(
                            color: isFuture ? Colors.transparent : colorFor(count),
                            borderRadius: BorderRadius.circular(3),
                            border: isFuture
                                ? null
                                : Border.all(color: p.border, width: 0.6),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
    ];

    final t = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          reverse: true,
          child: Row(children: columns),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              EarStrings.heatmapLegendLess,
              style: t.labelSmall?.copyWith(color: p.textMuted),
            ),
            const SizedBox(width: 4),
            for (final c in [0, 1, 2, 3])
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorFor(c),
                    borderRadius: BorderRadius.circular(2.5),
                    border: Border.all(color: p.border, width: 0.6),
                  ),
                ),
              ),
            const SizedBox(width: 4),
            Text(
              EarStrings.heatmapLegendMore,
              style: t.labelSmall?.copyWith(color: p.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
