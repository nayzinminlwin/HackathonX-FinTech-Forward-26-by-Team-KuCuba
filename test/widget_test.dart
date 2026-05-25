import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:eternal_guardian/app.dart';
import 'package:eternal_guardian/providers/analysis_provider.dart';
import 'package:eternal_guardian/providers/stats_provider.dart';

import 'support/test_analysis_api_service.dart';

void main() {
  testWidgets('Scam detector home renders', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AnalysisProvider(const TestAnalysisApiService()),
          ),
          ChangeNotifierProvider(create: (_) => StatsProvider()),
        ],
        child: const KuCubaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eternal Guardian'), findsOneWidget);
    expect(find.text('Scam Detector'), findsOneWidget);
    expect(find.text('Quick Scan'), findsOneWidget);
  });
}
