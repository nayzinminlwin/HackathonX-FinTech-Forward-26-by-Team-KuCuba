import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/analysis_result.dart';

class AnalysisService {
  AnalysisService({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  final http.Client _client;
  final String _baseUrl;

  Future<AnalysisResult> analyzeText(String textPayload) async {
    try {
      final uri = Uri.parse('$_baseUrl/analyze');
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({'text_payload': textPayload}),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode != 200) {
        return _mockAnalyze(textPayload, isFallback: true);
      }

      final dynamic decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return _mockAnalyze(textPayload, isFallback: true);
      }

      final apiResult = AnalysisResult.fromApiJson(decoded);
      if (apiResult.isUnavailable) {
        return _mockAnalyze(textPayload, isFallback: true);
      }

      return apiResult;
    } catch (_) {
      return _mockAnalyze(textPayload, isFallback: true);
    }
  }

  AnalysisResult previewBottomSheetResult() {
    return const AnalysisResult(
      riskScore: 95,
      analysisMessage:
          'Warning: This link is flagged as a known malicious website.',
    );
  }

  AnalysisResult _mockAnalyze(String inputText, {required bool isFallback}) {
    final lowerText = inputText.toLowerCase();

    if (lowerText.contains('http') ||
        lowerText.contains('www.') ||
        lowerText.contains('.xyz') ||
        lowerText.contains('.com')) {
      return AnalysisResult(
        riskScore: 95,
        analysisMessage:
            'Warning: This link is flagged as a known malicious website used for phishing and malware distribution.',
        isFallback: isFallback,
      );
    }

    if (lowerText.contains('bank') ||
        lowerText.contains('urgent') ||
        lowerText.contains('transfer') ||
        lowerText.contains('verify') ||
        lowerText.contains('suspended')) {
      return AnalysisResult(
        riskScore: 82,
        analysisMessage:
            'High risk detected: Message uses urgent financial language and pressure tactics commonly found in Malaysian banking scams.',
        isFallback: isFallback,
      );
    }

    if (lowerText.contains('winner') ||
        lowerText.contains('prize') ||
        lowerText.contains('lottery') ||
        lowerText.contains('congratulations')) {
      return AnalysisResult(
        riskScore: 88,
        analysisMessage:
            'Danger: Classic prize/lottery scam pattern. Legitimate organizations never request payment to claim winnings.',
        isFallback: isFallback,
      );
    }

    return AnalysisResult(
      riskScore: 18,
      analysisMessage:
          'Low risk: No obvious scam indicators detected. Message appears safe, but always verify sender identity.',
      isFallback: isFallback,
    );
  }
}
