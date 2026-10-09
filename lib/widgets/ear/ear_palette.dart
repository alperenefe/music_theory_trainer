import 'package:flutter/material.dart';

import '../../theme/design_tokens.dart';

/// Kulak eğitimi ekranları için açık/koyu temaya duyarlı renkler.
///
/// Uygulama `ThemeMode.system` kullandığı için sabit beyaz metin açık temada
/// görünmez oluyordu; bu ekranlar renklerini buradan alır.
@immutable
final class EarPalette {
  const EarPalette._({
    required this.dark,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.surface,
    required this.surfaceSunken,
    required this.surfaceLocked,
    required this.border,
    required this.track,
    required this.success,
    required this.danger,
    required this.gold,
    required this.info,
    required this.shadow,
  });

  final bool dark;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color surface;
  final Color surfaceSunken;
  final Color surfaceLocked;
  final Color border;
  final Color track;

  /// Metin olarak okunabilir durum renkleri (açık temada daha koyu tonlar).
  final Color success;
  final Color danger;
  final Color gold;
  final Color info;
  final Color shadow;

  static const _dark = EarPalette._(
    dark: true,
    textPrimary: DesignTokens.white,
    textSecondary: DesignTokens.slate300,
    textMuted: DesignTokens.slate400,
    surface: Color(0xF21E293B), // slate800 @ 95%
    surfaceSunken: Color(0xB30F172A), // slate900 @ 70%
    surfaceLocked: Color(0x990F172A), // slate900 @ 60%
    border: DesignTokens.slate700,
    track: DesignTokens.slate700,
    success: DesignTokens.earEmerald,
    danger: DesignTokens.rose400,
    gold: DesignTokens.earGold,
    info: DesignTokens.blue500,
    shadow: Color(0x59020617),
  );

  static const _light = EarPalette._(
    dark: false,
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF334155),
    textMuted: Color(0xFF64748B),
    surface: Color(0xFFFFFFFF),
    surfaceSunken: Color(0xFFF1F5F9),
    surfaceLocked: Color(0xFFF1F5F9),
    border: Color(0xFFE2E8F0),
    track: Color(0xFFE2E8F0),
    success: Color(0xFF047857),
    danger: Color(0xFFBE123C),
    gold: Color(0xFFB45309),
    info: Color(0xFF1D4ED8),
    shadow: Color(0x140F172A),
  );

  static EarPalette of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}
