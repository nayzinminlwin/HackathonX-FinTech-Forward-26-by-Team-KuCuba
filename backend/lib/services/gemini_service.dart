import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini LLM service for scam text analysis.
///
/// Pipeline Step 3: Called only when Safe Browsing (Step 2) has NOT flagged
/// a threat. Uses the exact few-shot system prompt from Phase 1 §2.5.
class GeminiService {
  static const String defaultModelName = 'gemini-2.5-flash-lite';

  final GenerativeModel _model;
  final String modelName;

  GeminiService({
    required String apiKey,
    this.modelName = defaultModelName,
  }) : _model = GenerativeModel(
          model: modelName,
          apiKey: apiKey,
          systemInstruction: Content.text(_systemPrompt),
          generationConfig: GenerationConfig(
            temperature: 0.1,
            responseMimeType: 'application/json',
            maxOutputTokens: 160,
          ),
        );

  /// Exact few-shot system prompt from Phase 1 §2.5.
  static const String _systemPrompt = '''
You are an expert Malaysian cybersecurity analyst specialising in scam detection.
Analyse the following text message or conversation. Evaluate for:
  1. Look-alike or typosquatting domains, including missing letters or number substitutions.
  2. Deceptive subdomains where a trusted brand appears before the real registered domain.
  3. URL shorteners or obfuscated links that hide the final destination. A shortener alone is not proof of a scam; treat it as caution/grey-area evidence and focus on the surrounding message intent.
  4. Non-standard or cheap TLDs used with trusted brand names, such as .xyz, .top, .cc, or .biz.
  5. Open redirect patterns where a trusted domain contains redirect, url, next, or target parameters to another site.

LANGUAGE:
- If the input message is in Malay, respond in Malay.
- If the input message is in English, respond in English.
- If the input mixes languages, use the dominant language.
SCORING CALIBRATION:
- If the only concern is a shortened URL and the message is otherwise normal, score 31-45 (caution/yellow), not green and not high-risk.
EXAMPLES OF KNOWN MALAYSIAN SCAMS:
1. "Polis here. Your IC linked to money laundering case. Transfer RM5,000 to this acc to clear your name." → risk_score: 95
2. "Tahniah! You won RM10,000 Shopee voucher. Click link to claim: bit.ly/xy123" → risk_score: 88
3. "Hi, I'm from LHDN. You have unpaid taxes. Share your TAC number to verify." → risk_score: 92
4. "Saya agent Macau Scam task job. Setiap task RM50-RM300. Modal awal RM500." → risk_score: 90
5. "Your Maybank account will be frozen. Update details at maybank-secure-login.com" → risk_score: 85

EXAMPLES OF SAFE MESSAGES:
1. "Hey, are we still on for lunch tomorrow?" → risk_score: 3
2. "Your Grab order has arrived at the lobby." → risk_score: 5
3. "Meeting at 3pm in Room A confirmed. Bring the quarterly report." → risk_score: 2
4. "Happy Birthday! Wishing you all the best 🎂" → risk_score: 1
5. "Mak, I'll be home late tonight. Dinner without me." → risk_score: 2

RESPOND WITH ONLY VALID JSON IN THIS EXACT FORMAT:
{"risk_score": <integer 1-100>, "analysis_message": "<max 2 sentences explaining why>"}''';

  /// Analyses [text] using Gemini and returns a parsed JSON map.
  ///
  /// Returns `null` if the API call fails, the response is empty,
  /// or the response cannot be parsed as valid JSON.
  Future<Map<String, dynamic>?> analyzeText(
    String text, {
    String? urlContext,
  }) async {
    try {
      final promptText = urlContext == null || urlContext.trim().isEmpty
          ? text
          : '$text\n\nURL analysis context:\n$urlContext';

      final response = await _model.generateContent([
        Content.text(promptText),
      ]);

      final responseText = response.text;
      if (responseText == null || responseText.trim().isEmpty) {
        print('[gemini] Empty response from Gemini API.');
        return null;
      }

      // Parse the JSON response
      final parsed = jsonDecode(responseText) as Map<String, dynamic>;

      // Validate expected keys exist
      if (!parsed.containsKey('risk_score') ||
          !parsed.containsKey('analysis_message')) {
        print('[gemini] Response missing required keys: $responseText');
        return null;
      }

      return parsed;
    } catch (e) {
      print('[gemini] Error during Gemini analysis: $e');
      return null;
    }
  }
}
