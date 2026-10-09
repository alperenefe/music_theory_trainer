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
      // Uygulama koyu temaya göre tasarlandı (DesignTokens'taki tüm renkler
      // sabit koyu-tema değerleri: white/slate900 gibi). Yalnızca kulak
      // eğitimi modülü (EarPalette) açık temaya da uyumlu hale getirildi;
      // geri kalan her ekran (ana ekran, gitar, MCQ, tuner, istatistik)
      // sistem açık temadayken bozuk/görünmez metin riski taşıyordu. Bu
      // yüzden tema tek ve sabit tutuluyor: ThemeMode.system yerine her
      // zaman koyu tema.
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

