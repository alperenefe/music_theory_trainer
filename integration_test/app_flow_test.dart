import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:music_theory_trainer/app.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'practice_prefs_v1':
          '{"poolMinMidi":60,"poolMaxMidi":84,"goalKind":null,"goalTarget":500,"goalProgress":0,"goalStartedAtMillis":0,"soundEnabled":true,"onboardingDone":true}',
    });
  });

  testWidgets('entegrasyon: yerleştir ekranına gidilir', (tester) async {
    await tester.pumpWidget(const MusicTheoryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text(AppStrings.placementTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(AppStrings.confirm), findsOneWidget);
    expect(find.text(AppStrings.targetLabel), findsOneWidget);
  });

  testWidgets('entegrasyon: çoktan seçmeli açılır', (tester) async {
    await tester.pumpWidget(const MusicTheoryApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await tester.tap(find.text(AppStrings.mcqTitle));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.text(AppStrings.next), findsNothing);
  });
}
