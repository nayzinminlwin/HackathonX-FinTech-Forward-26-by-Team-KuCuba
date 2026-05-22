import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';

/// Gemini LLM service for scam text analysis.
///
/// Pipeline Step 3: Called only when Safe Browsing (Step 2) has NOT flagged
/// a threat. Uses the exact few-shot system prompt from Phase 1 §2.5.
class GeminiService {
  final GenerativeModel _model;

  GeminiService({required String apiKey})
      : _model = GenerativeModel(
          model: 'gemini-2.5-flash',
          apiKey: apiKey,
          systemInstruction: Content.text(_systemPrompt),
          generationConfig: GenerationConfig(
            temperature: 0.1,
            responseMimeType: 'application/json',
          ),
        );

  /// Exact few-shot system prompt from Phase 1 §2.5.
  static const String _systemPrompt = '''
You are an expert Malaysian cybersecurity analyst specialising in scam detection.
Analyse the following text message or conversation. Evaluate for:
- Urgency tactics and pressure language
- Financial requests (bank transfers, e-wallet top-ups, TAC/OTP sharing)
- Emotional manipulation (fear, greed, sympathy)
- Impersonation of authorities (PDRM, LHDN, Bank Negara, Pos Malaysia)
- Suspicious links or requests to install apps

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
  Future<Map<String, dynamic>?> analyzeText(String text) async {
    try {
      final response = await _model.generateContent([
        Content.text(text),
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
