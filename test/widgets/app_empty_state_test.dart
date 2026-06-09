import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_theory_trainer/l10n/app_strings.dart';
import 'package:music_theory_trainer/widgets/feedback/app_empty_state.dart';

void main() {
  testWidgets('AppEmptyState.noData metinleri gösterir', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: AppEmptyState.noData())),
    );
    expect(find.text(AppStrings.noData), findsOneWidget);
    expect(find.text(AppStrings.emptyStateHint), findsOneWidget);
  });
}
