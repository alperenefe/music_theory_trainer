import 'package:flutter/material.dart';

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 24;
  static const double xxl = 32;
  static const double hero = 40;

  static const EdgeInsets screenH = EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets screenHV = EdgeInsets.symmetric(
    horizontal: md,
    vertical: lg,
  );
  static const EdgeInsets cardPad = EdgeInsets.all(lg);
  static const EdgeInsets cardPadDense = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );
  static const double cardGap = md;
  static const double sectionGap = xl;
  static const double listItemGap = sm;
  static const double staffPaintWidthScale = 1.04;
  /// Portede yerleştir: parmakla işaretleme için minimum yükseklik.
  static const double staffAreaHeight = 440;
  static const double mcqStaffAreaHeight = 360;

  static const double practiceActionHeight = 48;
}

abstract final class AppRadii {
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 22;
  static const double xl = 28;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration medium = Duration(milliseconds: 320);
  static const Curve curve = Curves.easeOutCubic;
}
