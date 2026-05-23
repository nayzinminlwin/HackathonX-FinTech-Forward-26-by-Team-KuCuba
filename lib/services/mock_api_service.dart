import '../models/analysis_result.dart';
import 'api_service.dart';

class MockApiService implements AnalysisApiService {
  @override
  Future<AnalysisResult> analyze(String textPayload) async {
    await Future<void>.delayed(const Duration(milliseconds: 1500));

    final lowerText = textPayload.toLowerCase();

    if (lowerText.contains('transfer') ||
        lowerText.contains('tac') ||
        lowerText.contains('polis') ||
        lowerText.contains('lhdn')) {
      return const AnalysisResult(
        riskScore: 88,
        analysisMessage:
            'This message contains hallmarks of a known Malaysian scam involving authority impersonation and financial requests.',
      );
    }

    if (lowerText.contains('http') ||
        lowerText.contains('www') ||
        lowerText.contains('click')) {
      return const AnalysisResult(
        riskScore: 65,
        analysisMessage:
            'This message contains a suspicious link. Exercise caution before clicking.',
      );
    }

    return const AnalysisResult(
      riskScore: 8,
      analysisMessage:
          'This message appears to be a normal, safe conversation.',
    );
  }
}
