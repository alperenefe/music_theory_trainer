import 'package:flutter/material.dart';

import 'l10n/app_strings.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

final class MusicTheoryApp extends StatefulWidget {
  const MusicTheoryApp({super.key});

  @override
  State<MusicTheoryApp> createState() => _MusicTheoryAppState();
}

final class _MusicTheoryAppState extends State<MusicTheoryApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppStrings.appTitle,
      theme: AppTheme.dark,
      builder: (context, child) {
        if (child == null) {
          return const SizedBox.shrink();
        }
        final mq = MediaQuery.of(context);
        final scaler = mq.textScaler.clamp(
          minScaleFactor: 0.88,
          maxScaleFactor: 1.28,
        );
        return MediaQuery(
          data: mq.copyWith(textScaler: scaler),
          child: child,
        );
      },
      home: const HomeScreen(),
    );
  }
}

