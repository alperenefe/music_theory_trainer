import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:music_theory_trainer/services/practice_prefs_repository.dart';
import 'package:music_theory_trainer/widgets/onboarding/app_onboarding_dialog.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'practice_prefs_v1': jsonEncode(
        const PracticePrefs(onboardingDone: false).toJson(),
      ),
    });
  });

  testWidgets('onboarding dialog hero ve sayfa sayaci', (tester) async {
    final repo = PracticePrefsRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (ctx) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showAppOnboardingDialog(context: ctx, repo: repo),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text(AppStrings.ob1Title), findsOneWidget);
    expect(find.byIcon(Icons.piano_rounded), findsOneWidget);

    await tester.tap(find.text(AppStrings.obNext));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('2 / 3'), findsOneWidget);
    expect(find.text(AppStrings.ob2Title), findsOneWidget);
  });
}
