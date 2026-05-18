import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

final class AttemptSparkline extends StatelessWidget {
  const AttemptSparkline({super.key, required this.series});

  final List<double> series;

  @override
  Widget build(BuildContext context) {
    if (series.length < 2) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: CustomPaint(painter: _SparkPainter(series)),
    );
  }
}

final class _SparkPainter extends CustomPainter {
  _SparkPainter(this.series);

  final List<double> series;

  @override
  void paint(Canvas canvas, Size size) {
    final pad = const EdgeInsets.only(left: 4, right: 4, top: 8, bottom: 4);
    final w = size.width - pad.horizontal;
    final h = size.height - pad.vertical;
    final n = series.length;
    if (n < 2 || w <= 0 || h <= 0) {
      return;
    }
    final pts = <Offset>[];
    for (var i = 0; i < n; i++) {
      final x = pad.left + i * w / (n - 1);
      final y = pad.top + h * (1 - series[i].clamp(0.0, 1.0));
      pts.add(Offset(x, y));
    }
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    final fill = Path()
      ..moveTo(pts.first.dx, pad.top + h)
      ..lineTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      fill.lineTo(pts[i].dx, pts[i].dy);
    }
    fill.lineTo(pts.last.dx, pad.top + h);
    fill.close();
    canvas.drawPath(
      fill,
      Paint()..color = DesignTokens.blue500.withValues(alpha: 0.12),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = DesignTokens.blue500.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.series != series;
}
