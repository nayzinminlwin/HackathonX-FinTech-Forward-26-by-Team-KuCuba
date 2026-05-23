import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eternal_guardian/app.dart';
import 'package:eternal_guardian/providers/analysis_provider.dart';
import 'package:eternal_guardian/services/mock_api_service.dart';

void main() {
  testWidgets('Scam detector home renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AnalysisProvider(MockApiService()),
        child: const KuCubaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Scam Detector'), findsOneWidget);
    expect(find.text('Check any message for scams'), findsOneWidget);
    expect(find.text('Analyze'), findsOneWidget);
  });
}
