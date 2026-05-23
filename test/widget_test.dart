import 'package:flutter_test/flutter_test.dart';

import 'package:eternal_guardian/app/app.dart';

void main() {
  testWidgets('Scam detector home renders', (WidgetTester tester) async {
    await tester.pumpWidget(const BeUApp());
    await tester.pumpAndSettle();

    expect(find.text('Be U'), findsOneWidget);
    expect(find.text('Quick Scan'), findsOneWidget);
  });
}
