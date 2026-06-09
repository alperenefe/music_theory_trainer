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

  testWidgets('reduced motion basma ölçeğini atlar', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: PressableScale(
              onTap: () {},
              child: const Text('Dokun'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Dokun'));
    await tester.pump(const Duration(milliseconds: 200));
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1);
  });
}
