import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/widgets/motion/pressable_scale.dart';

void main() {
  testWidgets('PressableScale onTap çağrılır', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PressableScale(
            onTap: () => tapped = true,
            child: const Text('Dokun'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Dokun'));
    expect(tapped, isTrue);
  });
}
