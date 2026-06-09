import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'design_tokens.dart';

final class FadeSlideTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.028),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

final class AppTheme {
  AppTheme._();

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: FadeSlideTransitionsBuilder(),
      TargetPlatform.iOS: FadeSlideTransitionsBuilder(),
      TargetPlatform.windows: FadeSlideTransitionsBuilder(),
      TargetPlatform.linux: FadeSlideTransitionsBuilder(),
      TargetPlatform.macOS: FadeSlideTransitionsBuilder(),
      TargetPlatform.fuchsia: FadeSlideTransitionsBuilder(),
    },
  );

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: DesignTokens.blue600,
      brightness: Brightness.light,
      surface: const Color(0xFFF8FAFC),
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      pageTransitionsTheme: _pageTransitions,
    );
    return _applyTypography(base, dark: false);
  }

  static ThemeData get dark {
    final colorScheme = ColorScheme.dark(
      surface: DesignTokens.slate950,
      primary: DesignTokens.blue600,
      secondary: DesignTokens.violet500,
      onPrimary: DesignTokens.white,
      onSurface: DesignTokens.slate200,
      outline: DesignTokens.slate600,
      surfaceContainerHighest: DesignTokens.slate800,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: DesignTokens.slate950,
      pageTransitionsTheme: _pageTransitions,
    );
    return _applyTypography(base, dark: true);
  }

  static ThemeData _applyTypography(ThemeData base, {required bool dark}) {
    final onSurface = dark ? DesignTokens.slate200 : const Color(0xFF0F172A);
    final muted = dark ? DesignTokens.slate400 : const Color(0xFF64748B);
    final inter = GoogleFonts.interTextTheme(base.textTheme);
    final textTheme = inter.copyWith(
      displaySmall: inter.displaySmall?.copyWith(
        letterSpacing: -0.6,
        height: 1.15,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      titleLarge: inter.titleLarge?.copyWith(
        letterSpacing: -0.35,
        height: 1.2,
        fontWeight: FontWeight.w800,
        color: onSurface,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        letterSpacing: -0.2,
        height: 1.25,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        letterSpacing: -0.1,
        height: 1.3,
        fontWeight: FontWeight.w700,
        color: onSurface,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(height: 1.45, color: onSurface),
      bodyMedium: inter.bodyMedium?.copyWith(height: 1.45, color: onSurface),
      bodySmall: inter.bodySmall?.copyWith(
        height: 1.42,
        color: muted,
      ),
      labelLarge: inter.labelLarge?.copyWith(height: 1.25, letterSpacing: 0.1),
    );
    final surfaceContainer = dark
        ? DesignTokens.slate800
        : const Color(0xFFFFFFFF);
    final border = dark ? DesignTokens.borderSubtle : const Color(0xFFE2E8F0);
    return base.copyWith(
      textTheme: textTheme,
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          foregroundColor: onSurface,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainer,
        selectedColor: DesignTokens.blue600.withValues(alpha: dark ? 0.22 : 0.14),
        disabledColor: dark ? DesignTokens.slate900 : const Color(0xFFF1F5F9),
        labelStyle: textTheme.labelMedium?.copyWith(
          color: dark ? DesignTokens.slate300 : const Color(0xFF475569),
          fontWeight: FontWeight.w600,
        ),
        secondaryLabelStyle: textTheme.labelMedium?.copyWith(
          color: dark ? DesignTokens.white : onSurface,
          fontWeight: FontWeight.w700,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        showCheckmark: false,
      ),
      cardTheme: CardThemeData(
        color: surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
