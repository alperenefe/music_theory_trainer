import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/app.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_pump_helpers.dart';

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

  testWidgets('egzersiz girişinde istatistik ve Başla', (tester) async {
    final binding = TestWidgetsFlutterBinding.instance;
    await binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() async {
      await binding.setSurfaceSize(null);
    });

    await tester.pumpWidget(const MusicTheoryApp());
    await pumpUntilHomeLoaded(tester);

    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.homeCtaTuner), findsOneWidget);
    expect(find.text(AppStrings.homeCtaGoals), findsOneWidget);

    await tester.tap(find.text(AppStrings.statsTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(AppStrings.statsFilterAll), findsOneWidget);
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await pumpUntilHomeLoaded(tester);

    await tester.tap(find.text(AppStrings.placementTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(AppStrings.exerciseStatsTitle), findsOneWidget);
    expect(find.widgetWithText(FilledButton, AppStrings.start), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, AppStrings.start));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(AppStrings.confirm), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.text(AppStrings.exerciseStatsTitle), findsOneWidget);
  });
}
