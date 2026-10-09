import 'package:flutter/material.dart';

import '../../l10n/ear_strings.dart';
import '../../models/ear_session_result.dart';
import '../../theme/design_tokens.dart';
import 'ear_palette.dart';

/// Son oturumlardaki doğruluk yüzdesini basit bir çizgi grafikle gösterir.
///
/// Kullanıcı geri bildirimi: "öğrenme eğrisi net mi" — ilerleme ekranında
/// sayılar vardı ama zaman içindeki gidişatı gösteren bir grafik yoktu.
/// [EarSessionResult.completedAt] + [EarSessionResult.accuracy] verisi zaten
/// tutuluyordu, sadece görselleştirilmiyordu.
final class AccuracyTrendChart extends StatelessWidget {
  const AccuracyTrendChart({super.key, required this.sessions});

  /// En yeniden en eskiye sıralı oturum listesi (ear history sırasıyla aynı).
  final List<EarSessionResult> sessions;

  @override
  Widget build(BuildContext context) {
    final p = EarPalette.of(context);
    final t = Theme.of(context).textTheme;

    if (sessions.length < 2) {
      return SizedBox(
        height: 64,
        child: Center(
          child: Text(
            EarStrings.trendEmpty,
            textAlign: TextAlign.center,
            style: t.bodySmall?.copyWith(color: p.textMuted),
          ),
        ),
      );
    }

    // Grafik eskiden yeniye okunur.
    final chronological = sessions.reversed.toList();
    final points = [for (final s in chronological) s.accuracy];
    final firstPct = (points.first * 100).round();
    final lastPct = (points.last * 100).round();
    final delta = lastPct - firstPct;

    String dateLabel(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            delta > 0
                ? EarStrings.trendDeltaUp(delta)
                : (delta < 0 ? EarStrings.trendDeltaDown(-delta) : EarStrings.trendDeltaFlat),
            style: t.labelMedium?.copyWith(
              color: delta > 0 ? p.success : (delta < 0 ? p.danger : p.textMuted),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: 110,
          width: double.infinity,
          child: CustomPaint(
            painter: _TrendPainter(
              points: points,
              lineColor: DesignTokens.earEmerald,
              gridColor: p.track,
              dark: p.dark,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${EarStrings.trendFirst}: ${dateLabel(chronological.first.completedAt)} · %$firstPct',
              style: t.labelSmall?.copyWith(color: p.textMuted),
            ),
            Text(
              '${EarStrings.trendLatest}: ${dateLabel(chronological.last.completedAt)} · %$lastPct',
              style: t.labelSmall?.copyWith(color: p.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.points,
    required this.lineColor,
    required this.gridColor,
    required this.dark,
  });

  /// 0.0-1.0 aralığında doğruluk oranları, eskiden yeniye sıralı.
  final List<double> points;
  final Color lineColor;
  final Color gridColor;
  final bool dark;

  static const _padding = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: dark ? 0.6 : 1.0)
      ..strokeWidth = 1;
    for (final frac in [0.0, 0.5, 1.0]) {
      final y = _padding + (size.height - _padding * 2) * (1 - frac);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.length < 2) return;

    final dx = (size.width - _padding * 2) / (points.length - 1);
    Offset offsetFor(int i) {
      final x = _padding + dx * i;
      final clamped = points[i].clamp(0.0, 1.0);
      final y = _padding + (size.height - _padding * 2) * (1 - clamped);
      return Offset(x, y);
    }

    final path = Path()..moveTo(offsetFor(0).dx, offsetFor(0).dy);
    for (var i = 1; i < points.length; i++) {
      final o = offsetFor(i);
      path.lineTo(o.dx, o.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(offsetFor(points.length - 1).dx, size.height - _padding)
      ..lineTo(offsetFor(0).dx, size.height - _padding)
      ..close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = lineColor.withValues(alpha: dark ? 0.18 : 0.12)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    final dotPaint = Paint()..color = lineColor;
    for (var i = 0; i < points.length; i++) {
      final o = offsetFor(i);
      canvas.drawCircle(o, i == points.length - 1 ? 4.0 : 2.2, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _TrendPainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.lineColor != lineColor ||
      oldDelegate.dark != dark;
}
