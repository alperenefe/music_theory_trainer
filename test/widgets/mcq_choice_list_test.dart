import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/widgets/exercise/mcq_choice_list.dart';

void main() {
  testWidgets('McqChoiceList 2x2 grid dört şık', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: McqChoiceList(
            options: const [
              'Do (4. oktav)',
              'Re (4. oktav)',
              'Mi (4. oktav)',
              'Fa (4. oktav)',
            ],
            correctLabel: 'Mi (4. oktav)',
            feedback: false,
            picked: null,
            onPick: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(GridView), findsOneWidget);
    expect(find.text('Do (4. oktav)'), findsOneWidget);
    expect(find.text('Fa (4. oktav)'), findsOneWidget);
  });
}
