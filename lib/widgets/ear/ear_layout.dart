import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';

/// Kulak eğitimi ekranlarında ortak duyarlı (responsive) yerleşim kuralları.
abstract final class EarLayout {
  /// Okunabilir içerik genişliği (tablet/masaüstünde satırlar uzamasın).
  static const readableMaxWidth = 720.0;

  /// Quiz'de iki sütuna geçiş eşiği (sol: dinleme, sağ: cevaplar).
  static const twoPaneMinWidth = 840.0;

  /// Cevap seçeneklerini 2 sütun ızgaraya dizme eşiği.
  static const optionGridMinWidth = 520.0;

  /// Liste ekranları için yatay dolgu: dar ekranda 16, genişte içeriği ortalar.
  static EdgeInsets pagePadding(
    double width, {
    double maxWidth = readableMaxWidth,
    double top = AppSpacing.md,
    double bottom = AppSpacing.xxl,
  }) {
    final side = width > maxWidth + AppSpacing.md * 2
        ? (width - maxWidth) / 2
        : AppSpacing.md;
    return EdgeInsets.fromLTRB(side, top, side, bottom);
  }

  /// Fiziksel klavye kısayollarının ipucu olarak gösterileceği platformlar.
  static bool get showKeyboardHints =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}

/// Çocuğu yatayda ortalar ve [maxWidth] ile sınırlar.
final class EarMaxWidth extends StatelessWidget {
  const EarMaxWidth({
    super.key,
    required this.child,
    this.maxWidth = EarLayout.readableMaxWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
