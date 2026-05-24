import 'package:eternal_guardian/models/scam_demo_models.dart';
import 'package:eternal_guardian/services/mock_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quick scan prize scam example returns high risk in mock mode', () async {
    final service = MockApiService();
    final prizeExample = quickScanExamples.singleWhere(
      (example) => example.preview == 'Prize scam pattern',
    );

    final result = await service.analyze(prizeExample.text);

    expect(result.riskScore, greaterThanOrEqualTo(70));
    expect(result.analysisMessage.toLowerCase(), contains('prize'));
  });

  test('normal conversation example remains low risk in mock mode', () async {
    final service = MockApiService();
    final normalExample = quickScanExamples.singleWhere(
      (example) => example.preview == 'Normal conversation',
    );

    final result = await service.analyze(normalExample.text);

    expect(result.riskScore, lessThanOrEqualTo(30));
  });
}
