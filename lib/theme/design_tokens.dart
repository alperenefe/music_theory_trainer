import 'package:flutter/material.dart';

abstract final class DesignTokens {
  static const slate950 = Color(0xFF020617);
  static const slate900 = Color(0xFF0F172A);
  static const slate800 = Color(0xFF1E293B);
  static const slate700 = Color(0xFF334155);
  static const slate600 = Color(0xFF475569);
  static const slate500 = Color(0xFF64748B);
  static const slate450 = Color(0xFF7C8EA3);
  static const slate400 = Color(0xFF9DB0C4);
  static const slate300 = Color(0xFFCBD5E1);
  static const slate200 = Color(0xFFE2E8F0);
  static const white = Color(0xFFFFFFFF);

  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const violet500 = Color(0xFF8B5CF6);
  static const violet400 = Color(0xFFA78BFA);

  static const green400 = Color(0xFF4ADE80);
  static const rose400 = Color(0xFFFB7185);
  static const streakOrange = Color(0xFFF97316);
  static const tunerCyan = Color(0xFF0891B2);

  /// Gitar perde tahtası
  static const fretboardWoodDark = Color(0xFF1A1108);
  static const fretboardWoodMid = Color(0xFF4A3820);
  static const fretboardFretGold = Color(0xFFE8C78A);
  static const fretboardFretLine = Color(0xFFC9A06A);
  static const fretboardInlay = Color(0xFFD8BE78);
  static const fretboardStringTint = Color(0xFF8A7050);

  /// Akort tel şeridi (E→e)
  static const tunerStringColors = [
    Color(0xFFE85D2C),
    Color(0xFFEF4444),
    Color(0xFFFBBF24),
    Color(0xFF22C55E),
    Color(0xFF3B82F6),
    Color(0xFFA855F7),
  ];

  static const statsProgressGradient = LinearGradient(
    colors: [blue500, violet500],
  );

  static const cardBg = slate800;
  static const borderSubtle = slate700;
  static const glowBlue = Color(0x332563EB);
}
