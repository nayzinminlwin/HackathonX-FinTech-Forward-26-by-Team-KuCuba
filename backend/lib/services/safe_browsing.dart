import 'dart:convert';
import 'package:http/http.dart' as http;

/// Client for the Google Safe Browsing Lookup API v4.
///
/// Pipeline Step 2: Called after URL extraction (Step 1).
/// If any URL is flagged as a threat, the handler should return
/// risk_score 100 immediately and skip Gemini (Step 3).
class SafeBrowsing {
  final String _apiKey;

  SafeBrowsing({required String apiKey}) : _apiKey = apiKey;

  /// Checks [urls] against Google Safe Browsing.
  ///
  /// Returns `true` if ANY url is flagged as a threat.
  /// Returns `false` if no threats are found, the API key is empty,
  /// or the API call fails (fail-open so we don't block the pipeline).
  Future<bool> checkUrls(List<String> urls) async {
    // --- Guard: empty key → skip Safe Browsing silently ---
    if (_apiKey.isEmpty) {
      print('[safe_browsing] API key is empty — skipping Safe Browsing check.');
      return false;
    }

    if (urls.isEmpty) return false;

    final uri = Uri.parse(
      'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$_apiKey',
    );

    // Build the request body per
    // https://developers.google.com/safe-browsing/v4/lookup-api#checking-urls
    final requestBody = {
      'client': {
        'clientId': 'kucuba-backend',
        'clientVersion': '1.0.0',
      },
      'threatInfo': {
        'threatTypes': [
          'MALWARE',
          'SOCIAL_ENGINEERING',
          'UNWANTED_SOFTWARE',
        ],
        'platformTypes': ['ANY_PLATFORM'],
        'threatEntryTypes': ['URL'],
        'threatEntries': urls.map((url) => {'url': url}).toList(),
      },
    };

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode != 200) {
        print('[safe_browsing] API returned status ${response.statusCode} — '
            'treating as no-threat (fail-open).');
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;

      // The API returns {"matches": [...]} when threats are found.
      // An empty JSON object {} means no threats.
      if (decoded.containsKey('matches')) {
        final matches = decoded['matches'] as List<dynamic>;
        if (matches.isNotEmpty) {
          print('[safe_browsing] ⚠ Threat detected! '
              '${matches.length} match(es) found.');
          return true;
        }
      }

      print('[safe_browsing] No threats detected.');
      return false;
    } catch (e) {
      // Network error, timeout, JSON parse failure, etc.
      // Fail-open: don't block the pipeline.
      print('[safe_browsing] Error calling API: $e — treating as no-threat.');
      return false;
    }
  }
}
