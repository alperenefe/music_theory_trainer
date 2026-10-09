import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';
import 'staff_geometry.dart';

enum StaffNoteFeedbackKind { normal, wrongPick, correctTarget }

final class TrebleStaffNoteSpec {
  const TrebleStaffNoteSpec({
    required this.slot,
    this.feedback = StaffNoteFeedbackKind.normal,
  });

  final int slot;
  final StaffNoteFeedbackKind feedback;

  @override
  bool operator ==(Object other) =>
      other is TrebleStaffNoteSpec &&
      other.slot == slot &&
      other.feedback == feedback;

  @override
  int get hashCode => Object.hash(slot, feedback);
}

/// Landmark notaların etiketleri (sounding MIDI → Türkçe kısa isim).
const _landmarkLabels = <int, String>{
  55: 'Sol', // slot +2, G4 yazılı — G anahtarının sarmal noktası
  48: 'Do',  // slot −2, C3 yazılı — orta Do (1. ek çizgi altı)
  65: 'Fa',  // slot +8, F4 yazılı — üst çizgi
};

final class TrebleStaffPainter extends CustomPainter {
  TrebleStaffPainter({
    required this.geometry,
    required this.notes,
    this.ledgerSlots = const [],
    this.highlightSlot,
    this.wrongHighlightSlot,
    this.correctHighlightSlot,
    this.landmarkSlots = const [],
  });

  final StaffGeometry geometry;
  final List<TrebleStaffNoteSpec> notes;
  final List<int> ledgerSlots;
  final int? highlightSlot;
  final int? wrongHighlightSlot;
  final int? correctHighlightSlot;

  /// Staff slotları — bu konumlara küçük referans etiket çizilir.
  final List<int> landmarkSlots;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = DesignTokens.slate400.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;
    for (final y in geometry.mainLineYs()) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
    final ledgerPaint = Paint()
      ..color = DesignTokens.slate400.withValues(alpha: 0.48)
      ..strokeWidth = 1.15;
    _drawLedgers(canvas, ledgerPaint);
    _drawClef(canvas);
    // Landmark ipuçları notaların arkasına çizilir.
    for (final s in landmarkSlots) {
      _drawLandmarkHint(canvas, s, size);
    }
    for (final n in notes) {
      _drawNote(canvas, n);
    }
    if (highlightSlot != null) {
      _drawHighlight(canvas, highlightSlot!, DesignTokens.blue600);
    }
    if (wrongHighlightSlot != null) {
      _drawHighlight(canvas, wrongHighlightSlot!, DesignTokens.rose400);
    }
    if (correctHighlightSlot != null) {
      _drawHighlight(canvas, correctHighlightSlot!, DesignTokens.green400);
    }
  }

  void _drawLedgers(Canvas canvas, Paint ledgerPaint) {
    final lx0 = geometry.noteHeadX - 20;
    final lx1 = geometry.noteHeadX + 20;
    final slots = <int>{...ledgerSlots};
    for (final n in notes) {
      final s = n.slot;
      if (s < 0 && s.isEven) {
        slots.add(s);
      } else if (s > 8 && s.isEven) {
        slots.add(s);
      }
    }
    for (final s in slots) {
      // Ledger çizgileri sadece çift slotlarda (tam çizgi pozisyonlarında)
      // anlamlıdır; tek slotlar notanın oturduğu boşluklardır. Bu kontrol
      // alt ve üst uçta simetrik olmalı — daha önce alt uç isEven kontrolü
      // yapmıyordu, bu da `ledgerSlots` ile doğrudan tek bir slot
      // geçildiğinde bir notanın boşluğunun ortasından çizgi çizebilirdi.
      if (s.isEven && (s < 0 || s > 8)) {
        final y = geometry.yForSlot(s);
        // Gerçek nota yazımında ledger çizgileri DÜZ (kesiksiz) çizilir —
        // kesikli çizgi bir tanı/hata göstergesi gibi görünüyordu.
        canvas.drawLine(Offset(lx0, y), Offset(lx1, y), ledgerPaint);
      }
    }
  }

  void _drawClef(Canvas canvas) {
    final fontSize = geometry.clefFontSize;
    final tp = TextPainter(
      text: TextSpan(
        text: '𝄞',
        style: TextStyle(
          color: DesignTokens.slate200,
          fontSize: fontSize,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final anchorY = (geometry.yForSlot(0) + geometry.yForSlot(8)) / 2;
    tp.paint(
      canvas,
      Offset(geometry.clefX, anchorY - tp.height * 0.5),
    );
  }

  void _drawNote(Canvas canvas, TrebleStaffNoteSpec n) {
    final cx = geometry.noteHeadX;
    final cy = geometry.yForSlot(n.slot);
    final headW = geometry.noteHeadWidth;
    final headH = geometry.noteHeadHeight;
    final oval = Path()
      ..addOval(
        Rect.fromCenter(center: Offset(cx, cy), width: headW, height: headH),
      );
    final Color fillColor;
    final Color strokeColor;
    switch (n.feedback) {
      case StaffNoteFeedbackKind.normal:
        fillColor = DesignTokens.white;
        strokeColor = DesignTokens.slate900;
      case StaffNoteFeedbackKind.wrongPick:
        fillColor = DesignTokens.rose400.withValues(alpha: 0.92);
        strokeColor = DesignTokens.rose400;
      case StaffNoteFeedbackKind.correctTarget:
        fillColor = DesignTokens.green400.withValues(alpha: 0.92);
        strokeColor = DesignTokens.green400;
    }
    final fill = Paint()..color = fillColor;
    final stroke = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(oval, fill);
    canvas.drawPath(oval, stroke);
    _drawStem(canvas, n, cx, cy, headW, strokeColor);
  }

  /// Nota sapı (stem) — gerçek nota yazımında her nota başının bir sapı
  /// vardır; bu olmadan notalar "çizgi üstünde nokta" gibi görünüyordu.
  /// Standart kural: orta çizgide (slot 4) veya üstünde olan notaların sapı
  /// AŞAĞI (kafanın soluna), altındakilerin sapı YUKARI (kafanın sağına)
  /// çizilir. Uzunluk yaklaşık 3.5 porte aralığı — engraving standardı.
  void _drawStem(
    Canvas canvas,
    TrebleStaffNoteSpec n,
    double cx,
    double cy,
    double headW,
    Color color,
  ) {
    final stemLength = geometry.halfLineSpacing * 7;
    final stemPaint = Paint()
      ..color = color
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;
    if (n.slot >= 4) {
      final x = cx - headW / 2 + 0.6;
      canvas.drawLine(Offset(x, cy), Offset(x, cy + stemLength), stemPaint);
    } else {
      final x = cx + headW / 2 - 0.6;
      canvas.drawLine(Offset(x, cy), Offset(x, cy - stemLength), stemPaint);
    }
  }

  void _drawHighlight(Canvas canvas, int slot, Color color) {
    final y = geometry.yForSlot(slot);
    final r = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(geometry.noteHeadX, y),
        width: geometry.noteHeadWidth * 1.5,
        height: geometry.noteHeadHeight * 1.85,
      ),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      r,
      Paint()..color = color.withValues(alpha: 0.28),
    );
  }

  /// Sağ kenara küçük not ismi yazar — referans nota ipucu.
  void _drawLandmarkHint(Canvas canvas, int slot, Size size) {
    final y = geometry.yForSlot(slot);
    // Sadece görünür aralıktaki slotlara çiz.
    if (y < -4 || y > size.height + 4) return;

    // Slota karşılık gelen sounding MIDI'yi bul ve etiketi al.
    String? label;
    for (final entry in _landmarkLabels.entries) {
      // Slot eşleşmesini geometry üzerinden değil, NotationPitch üzerinden
      // yapmak yerine sabit slot değerleriyle eşleştiriyoruz.
      if (slot == 2 && entry.key == 55) {
        label = entry.value;
        break;
      }
      if (slot == -2 && entry.key == 48) {
        label = entry.value;
        break;
      }
      if (slot == 8 && entry.key == 65) {
        label = entry.value;
        break;
      }
    }
    if (label == null) return;

    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: DesignTokens.violet400.withValues(alpha: 0.55),
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    // Sağ kenar — notanın sağına gelmesin diye küçük bir offset.
    final x = size.width - tp.width - 3;
    tp.paint(canvas, Offset(x, y - tp.height / 2));

    // Küçük bir nokta da çiz (etiketin soluna).
    canvas.drawCircle(
      Offset(x - 5, y),
      2.2,
      Paint()..color = DesignTokens.violet400.withValues(alpha: 0.45),
    );
  }

  @override
  bool shouldRepaint(covariant TrebleStaffPainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.highlightSlot != highlightSlot ||
        oldDelegate.wrongHighlightSlot != wrongHighlightSlot ||
        oldDelegate.correctHighlightSlot != correctHighlightSlot ||
        !listEquals(oldDelegate.notes, notes) ||
        !listEquals(oldDelegate.ledgerSlots, ledgerSlots) ||
        !listEquals(oldDelegate.landmarkSlots, landmarkSlots);
  }
}
