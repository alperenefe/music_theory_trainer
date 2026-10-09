import 'package:flutter/material.dart';

import '../../models/chord_shape.dart';
import '../../theme/design_tokens.dart';

/// Açık pozisyon akor şeması (solda en kalın 6. tel).
///
/// [problemStrings]: algılayıcının "eksik" ya da "fazla" bulduğu teller
/// (0 = 6. tel); bu tellerin üstüne kırmızı işaret çizilir.
final class ChordDiagram extends StatelessWidget {
  const ChordDiagram({
    super.key,
    required this.chord,
    this.width = 120,
    this.showName = true,
    this.problemStrings = const [],
    this.accent = DesignTokens.blue500,
  });

  final ChordShape chord;
  final double width;
  final bool showName;
  final List<int> problemStrings;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final height = width * 1.25;
    final diagram = SizedBox(
      width: width,
      height: height,
      child: CustomPaint(
        painter: _ChordPainter(chord: chord, problems: problemStrings, accent: accent),
      ),
    );
    return Semantics(
      label: '${chord.nameTr} (${chord.symbol}) akor şeması',
      child: showName
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chord.symbol,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: DesignTokens.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                Text(
                  chord.nameTr,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: DesignTokens.slate400,
                      ),
                ),
                const SizedBox(height: 6),
                ExcludeSemantics(child: diagram),
              ],
            )
          : ExcludeSemantics(child: diagram),
    );
  }
}

final class _ChordPainter extends CustomPainter {
  _ChordPainter({required this.chord, required this.problems, required this.accent});

  final ChordShape chord;
  final List<int> problems;
  final Color accent;

  static const _fretRows = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final topMargin = size.height * 0.16; // X / O işaretleri için
    final left = size.width * 0.12;
    final right = size.width * 0.88;
    final bottom = size.height * 0.96;
    final stringGap = (right - left) / 5;
    final fretGap = (bottom - topMargin) / _fretRows;

    final line = Paint()
      ..color = DesignTokens.slate400
      ..strokeWidth = 1.2;
    final nut = Paint()
      ..color = DesignTokens.slate200
      ..strokeWidth = 4;

    // Perde çizgileri.
    for (var f = 0; f <= _fretRows; f++) {
      final y = topMargin + f * fretGap;
      canvas.drawLine(Offset(left, y), Offset(right, y), f == 0 ? nut : line);
    }
    // Teller: solda kalın, sağda ince.
    for (var s = 0; s < 6; s++) {
      final x = left + s * stringGap;
      final thick = 1.0 + (5 - s) * 0.28;
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, bottom),
        Paint()
          ..color = DesignTokens.slate300
          ..strokeWidth = thick,
      );
    }

    final dot = Paint()..color = accent;
    final dotR = stringGap * 0.42;
    for (var s = 0; s < 6; s++) {
      final fret = chord.frets[s];
      final x = left + s * stringGap;
      final markerY = topMargin * 0.5;
      if (fret < 0) {
        final p = Paint()
          ..color = DesignTokens.slate500
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round;
        const r = 4.5;
        canvas.drawLine(Offset(x - r, markerY - r), Offset(x + r, markerY + r), p);
        canvas.drawLine(Offset(x - r, markerY + r), Offset(x + r, markerY - r), p);
      } else if (fret == 0) {
        canvas.drawCircle(
          Offset(x, markerY),
          4.5,
          Paint()
            ..color = DesignTokens.slate200
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      } else {
        final y = topMargin + (fret - 0.5) * fretGap;
        canvas.drawCircle(Offset(x, y), dotR, dot);
        final finger = chord.fingers[s];
        if (finger > 0) {
          final tp = TextPainter(
            text: TextSpan(
              text: '$finger',
              style: TextStyle(
                color: Colors.white,
                fontSize: dotR * 1.15,
                fontWeight: FontWeight.w900,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
        }
      }
    }

    // Sorunlu teller: telin üstüne kırmızı halka.
    for (final s in problems) {
      if (s < 0 || s > 5) continue;
      final x = left + s * stringGap;
      canvas.drawCircle(
        Offset(x, topMargin * 0.5),
        stringGap * 0.55,
        Paint()
          ..color = DesignTokens.rose400
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.4,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ChordPainter old) =>
      old.chord.id != chord.id ||
      old.accent != accent ||
      old.problems.length != problems.length ||
      !_sameInts(old.problems, problems);

  static bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
