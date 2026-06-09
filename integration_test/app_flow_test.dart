import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:music_theory_trainer/app.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const prefsJson =
      '{"poolMinMidi":60,"poolMaxMidi":84,"exerciseGoals":{},"soundEnabled":true,"onboardingDone":true,"referenceA4Hz":440}';

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'practice_prefs_v1': prefsJson,
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('practice_prefs_v1', prefsJson);
    await prefs.remove('practice_attempts_v1');
  });

  Future<void> pumpUntilHomeReady(WidgetTester tester) async {
    await tester.pumpWidget(const MusicTheoryApp());
    await tester.pump();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 50));
      if (find.text(AppStrings.placementTitle).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.text(AppStrings.appTitle), findsOneWidget);
    expect(find.text(AppStrings.placementTitle), findsOneWidget);
  }

  Future<void> openHomeRoute(WidgetTester tester, String title) async {
    await pumpUntilHomeReady(tester);
    final tile = find.text(title);
    await tester.ensureVisible(tile);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(tile);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  Future<void> tapStart(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.start));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
  }

  testWidgets(
    'entegrasyon: yerleştir ekranı açılır',
    (tester) async {
      await openHomeRoute(tester, AppStrings.placementTitle);
      await tapStart(tester);
      expect(find.text(AppStrings.confirm), findsOneWidget);
      expect(find.text(AppStrings.targetLabel), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'entegrasyon: egzersiz girişinde Başla',
    (tester) async {
      await openHomeRoute(tester, AppStrings.placementTitle);
      expect(find.widgetWithText(FilledButton, AppStrings.start), findsOneWidget);
      expect(find.text(AppStrings.exerciseStatsTitle), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'entegrasyon: çoktan seçmeli açılır',
    (tester) async {
      await openHomeRoute(tester, AppStrings.mcqTitle);
      await tapStart(tester);
      expect(find.text(AppStrings.next), findsNothing);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'entegrasyon: hedef ekranı açılır',
    (tester) async {
      await pumpUntilHomeReady(tester);
      await tester.tap(find.text(AppStrings.homeCtaGoals));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text(AppStrings.goalSave), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'entegrasyon: gitar MCQ açılır',
    (tester) async {
      await openHomeRoute(tester, AppStrings.guitarMcqTitle);
      await tapStart(tester);
      expect(find.text(AppStrings.guitarMcqDesc), findsWidgets);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'entegrasyon: gitar bul açılır',
    (tester) async {
      await openHomeRoute(tester, AppStrings.guitarFindTitle);
      await tapStart(tester);
      expect(find.text(AppStrings.guitarTapHint), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'entegrasyon: gitar çal ekranı açılır',
    (tester) async {
      await openHomeRoute(tester, AppStrings.guitarPlayTitle);
      await tapStart(tester);
      expect(find.text(AppStrings.guitarPlayPreview), findsOneWidget);
      expect(find.text(AppStrings.guitarPlayChangeTarget), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  testWidgets(
    'entegrasyon: akort ekranı açılır',
    (tester) async {
      await openHomeRoute(tester, AppStrings.tunerTitle);
      expect(find.text(AppStrings.tunerRefA4), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  tearDownAll(() async {
    binding.reportData = <String, dynamic>{'integration': 'completed'};
  });
}
