import 'package:flutter/material.dart';

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
    final inter = base.textTheme;
    final textTheme = inter.copyWith(
      displaySmall: inter.displaySmall?.copyWith(
        letterSpacing: -0.6,
        height: 1.15,
        fontWeight: FontWeight.w800,
      ),
      titleLarge: inter.titleLarge?.copyWith(
        letterSpacing: -0.35,
        height: 1.2,
        fontWeight: FontWeight.w800,
      ),
      titleMedium: inter.titleMedium?.copyWith(
        letterSpacing: -0.2,
        height: 1.25,
        fontWeight: FontWeight.w700,
      ),
      titleSmall: inter.titleSmall?.copyWith(
        letterSpacing: -0.1,
        height: 1.3,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: inter.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: inter.bodyMedium?.copyWith(height: 1.45),
      bodySmall: inter.bodySmall?.copyWith(
        height: 1.42,
        color: DesignTokens.slate400,
      ),
      labelLarge: inter.labelLarge?.copyWith(height: 1.25, letterSpacing: 0.1),
    );
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
      cardTheme: CardThemeData(
        color: DesignTokens.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: DesignTokens.borderSubtle),
        ),
      ),
    );
  }
}
