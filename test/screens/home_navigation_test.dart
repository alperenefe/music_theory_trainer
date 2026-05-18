import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/app.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'practice_prefs_v1': jsonEncode(
        const PracticePrefs(onboardingDone: true).toJson(),
      ),
    });
  });

  setUp(() async {
    final p = await SharedPreferences.getInstance();
    await p.clear();
    await p.setString(
      'practice_prefs_v1',
      jsonEncode(const PracticePrefs(onboardingDone: true).toJson()),
    );
  });
  testWidgets('ana ekrandan yerleştir ve istatistik akışı', (tester) async {
    final binding = TestWidgetsFlutterBinding.instance;
    await binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const MusicTheoryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text(AppStrings.appTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.placementTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(AppStrings.confirm), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    await tester.scrollUntilVisible(
      find.text(AppStrings.statsTitle),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AppStrings.statsTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.text(AppStrings.clearStats), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    // Ana sayfaya döndük; app barı göz ardı edip ekranın yüklü olduğunu doğrula
    expect(find.text(AppStrings.clearStats), findsNothing);
  });
}
