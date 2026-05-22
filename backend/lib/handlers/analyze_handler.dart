import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/link_extractor.dart';
import '../services/safe_browsing.dart';
import '../services/gemini_service.dart';
import '../models/analysis_result.dart';

/// Handler for POST /analyze.
///
/// Full Phase 1 pipeline (Sectors 1–3):
///   1. Parse {"text_payload": "<string>"} from the request body
///   2. Step 1: URL extraction via [LinkExtractor]
///   3. Step 2: Google Safe Browsing check via [SafeBrowsing]
///      → If threat detected: returns risk_score 100 immediately, skips Gemini
///   4. Step 3: Gemini LLM analysis via [GeminiService]
///      → Parse JSON, validate risk_score 1–100 (clamp if needed)
///   5. On any failure: returns the error sentinel (risk_score -1)
class AnalyzeHandler {
  final SafeBrowsing _safeBrowsing;
  final GeminiService? _geminiService;

  AnalyzeHandler({
    required SafeBrowsing safeBrowsing,
    GeminiService? geminiService,
  })  : _safeBrowsing = safeBrowsing,
        _geminiService = geminiService;

  /// Handles an incoming POST /analyze request.
  Future<Response> handle(Request request) async {
    try {
      // --- Parse request body ---
      final bodyString = await request.readAsString();
      final Map<String, dynamic> body;

      try {
        body = jsonDecode(bodyString) as Map<String, dynamic>;
      } catch (_) {
        // Malformed JSON
        return _jsonResponse(AnalysisResult.error());
      }

      final textPayload = body['text_payload'];
      if (textPayload == null ||
          textPayload is! String ||
          textPayload.trim().isEmpty) {
        return _jsonResponse(AnalysisResult.error());
      }

      // --- Step 1: URL extraction ---
      final urls = LinkExtractor.extractUrls(textPayload);

      // Log extracted URLs (no text_payload logged per rule.md §10)
      print('[analyze] Extracted ${urls.length} URL(s): $urls');

      // --- Step 2: Safe Browsing ---
      if (urls.isNotEmpty) {
        final isThreat = await _safeBrowsing.checkUrls(urls);
        if (isThreat) {
          // Threat detected — return 100 immediately, do NOT call Gemini.
          print('[analyze] Safe Browsing threat detected — returning 100.');
          return _jsonResponse(const AnalysisResult(
            riskScore: 100,
            analysisMessage:
                'Warning: This message contains a link flagged as '
                'malicious (phishing/malware). Do not click it.',
          ));
        }
      }

      // --- Step 3: Gemini LLM analysis ---
      if (_geminiService == null) {
        print('[analyze] Gemini service not available (no API key).');
        return _jsonResponse(AnalysisResult.error());
      }

      final geminiService = _geminiService;
      final geminiResult = await geminiService.analyzeText(textPayload);

      if (geminiResult == null) {
        // Gemini call failed or returned unparseable response
        print('[analyze] Gemini returned null — using error sentinel.');
        return _jsonResponse(AnalysisResult.error());
      }

      // --- Validate and clamp risk_score ---
      final rawScore = geminiResult['risk_score'];
      final rawMessage = geminiResult['analysis_message'];

      if (rawScore == null || rawMessage == null) {
        print('[analyze] Gemini response missing required fields.');
        return _jsonResponse(AnalysisResult.error());
      }

      // risk_score may come as int or double from JSON
      int riskScore;
      if (rawScore is int) {
        riskScore = rawScore;
      } else if (rawScore is double) {
        riskScore = rawScore.round();
      } else if (rawScore is String) {
        riskScore = int.tryParse(rawScore) ?? -1;
        if (riskScore == -1) {
          print('[analyze] Could not parse risk_score from string: $rawScore');
          return _jsonResponse(AnalysisResult.error());
        }
      } else {
        print('[analyze] Unexpected risk_score type: ${rawScore.runtimeType}');
        return _jsonResponse(AnalysisResult.error());
      }

      // Clamp to 1–100 range (rule.md §3.2)
      riskScore = riskScore.clamp(1, 100);

      final analysisMessage = rawMessage is String
          ? rawMessage
          : rawMessage.toString();

      print('[analyze] Gemini result — risk_score: $riskScore');

      return _jsonResponse(AnalysisResult(
        riskScore: riskScore,
        analysisMessage: analysisMessage,
      ));
    } catch (e) {
      // Catch-all: never crash, never return a 5xx with no body (rule.md §3.1)
      print('[analyze] Unhandled error: $e');
      return _jsonResponse(AnalysisResult.error());
    }
  }

  /// Builds a JSON [Response] from an [AnalysisResult].
  Response _jsonResponse(AnalysisResult result) {
    return Response.ok(
      jsonEncode(result.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }
}
