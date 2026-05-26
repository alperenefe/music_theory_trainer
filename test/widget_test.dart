import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/app.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/models/practice_prefs.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_pump_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'practice_prefs_v1': jsonEncode(
        const PracticePrefs(onboardingDone: true).toJson(),
      ),
    });
  });
  testWidgets('uygulama açılır', (tester) async {
    await tester.pumpWidget(const MusicTheoryApp());
    await pumpUntilHomeLoaded(tester);
    expect(find.text(AppStrings.appTitle), findsOneWidget);
  });
}
