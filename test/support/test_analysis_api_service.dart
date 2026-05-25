import 'package:eternal_guardian/models/analysis_result.dart';
import 'package:eternal_guardian/services/api_service.dart';

class TestAnalysisApiService implements AnalysisApiService {
  const TestAnalysisApiService({
    this.result = const AnalysisResult(
      riskScore: 88,
      analysisMessage: 'Test analysis result.',
    ),
    this.delay = const Duration(milliseconds: 1),
  });

  final AnalysisResult result;
  final Duration delay;

  @override
  Future<AnalysisResult> analyze(String textPayload) async {
    await Future<void>.delayed(delay);
    return result;
  }
}
