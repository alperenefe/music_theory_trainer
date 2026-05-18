import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/screens/goals/goal_kind_chips.dart';

void main() {
  testWidgets('GoalKindChips hedef türü seçimi', (tester) async {
    String? kind;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalKindChips(goalKind: null, onChanged: (v) => kind = v),
        ),
      ),
    );
    await tester.tap(find.text(AppStrings.placementTitle));
    await tester.pump();
    expect(kind, 'placement');
  });
}
