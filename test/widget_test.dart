import 'package:flutter_test/flutter_test.dart';


void main() {
  testWidgets('Scam detector home renders', (WidgetTester tester) async {
    await tester.pumpAndSettle();

    expect(find.text('Be U'), findsOneWidget);
    expect(find.text('Quick Scan'), findsOneWidget);
  });
}
