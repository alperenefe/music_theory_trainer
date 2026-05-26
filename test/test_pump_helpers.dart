import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';

/// Async home yüklenene kadar pump (skeleton sonrası).
Future<void> pumpUntilHomeLoaded(WidgetTester tester) async {
  await tester.pump();
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (find.text(AppStrings.homeCtaTuner).evaluate().isNotEmpty) {
      return;
    }
  }
}
