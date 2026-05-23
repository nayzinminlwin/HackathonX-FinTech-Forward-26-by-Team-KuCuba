import 'package:flutter_test/flutter_test.dart';
import 'package:eternal_guardian/main.dart';

void main() {
  testWidgets('Scam detector home renders', (WidgetTester tester) async {
    await tester.pumpWidget(const EternalGuardianApp());
    await tester.pumpAndSettle();

    expect(find.text('Be U'), findsOneWidget);
    expect(find.text('Quick Scan'), findsOneWidget);
  });
}
