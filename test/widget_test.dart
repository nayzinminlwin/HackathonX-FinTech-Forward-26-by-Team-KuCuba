// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.


import 'package:flutter_test/flutter_test.dart';

import 'package:eternal_guardian/main.dart';

void main() {
  testWidgets('shows the home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const EternalGuardianApp());
    await tester.pumpAndSettle();

    expect(find.text('Eternal Guardian'), findsOneWidget);
    expect(
        find.text('Phase 1 UI - Waiting for Ariff tomorrow!'), findsOneWidget);
  });
}
