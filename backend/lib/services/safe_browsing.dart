import 'package:dio/dio.dart';

/// Client for the Google Safe Browsing Lookup API v4.
///
/// Pipeline Step 2: Called after URL extraction (Step 1).
/// If any URL is flagged as a threat, the handler should return
/// risk_score 100 immediately and skip Gemini (Step 3).
class SafeBrowsing {
  static const Duration _cacheTtl = Duration(minutes: 10);

  final String _apiKey;
  final Dio _dio;
  final Map<String, _CacheEntry<bool>> _cache = {};

  SafeBrowsing({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 2),
          receiveTimeout: const Duration(seconds: 2),
        ));

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

    final uniqueUrls = urls.toSet().toList();
    if (uniqueUrls.isEmpty) return false;

    final cachedResults = <bool>[];
    final uncachedUrls = <String>[];
    for (final url in uniqueUrls) {
      final cached = _getCached(url);
      if (cached == null) {
        uncachedUrls.add(url);
      } else {
        cachedResults.add(cached);
      }
    }

    if (cachedResults.any((isThreat) => isThreat)) {
      print('[safe_browsing] Threat found in cache.');
      return true;
    }

    if (uncachedUrls.isEmpty) {
      print('[safe_browsing] Cache hit for ${uniqueUrls.length} URL(s).');
      return false;
    }

    final url =
        'https://safebrowsing.googleapis.com/v4/threatMatches:find?key=$_apiKey';

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
        'threatEntries': uncachedUrls.map((u) => {'url': u}).toList(),
      },
    };

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        url,
        data: requestBody,
        options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json,
        ),
      );

      if (response.statusCode != 200) {
        print('[safe_browsing] API returned status ${response.statusCode} — '
            'treating as no-threat (fail-open).');
        return false;
      }

      final decoded = response.data;
      if (decoded == null) {
        print('[safe_browsing] Empty response body — treating as no-threat.');
        return false;
      }

      // The API returns {"matches": [...]} when threats are found.
      // An empty JSON object {} means no threats.
      if (decoded.containsKey('matches')) {
        final matches = decoded['matches'] as List<dynamic>;
        if (matches.isNotEmpty) {
          final matchedUrls = matches
              .map((match) {
                if (match is! Map) return null;
                final threat = match['threat'];
                if (threat is! Map) return null;
                final matchedUrl = threat['url'];
                return matchedUrl is String ? matchedUrl : null;
              })
              .whereType<String>()
              .toSet();

          if (matchedUrls.isNotEmpty) {
            for (final checkedUrl in uncachedUrls) {
              _setCached(checkedUrl, matchedUrls.contains(checkedUrl));
            }
          }

          print('[safe_browsing] ⚠ Threat detected! '
              '${matches.length} match(es) found.');
          return true;
        }
      }

      for (final checkedUrl in uncachedUrls) {
        _setCached(checkedUrl, false);
      }

      print('[safe_browsing] No threats detected.');
      return false;
    } on DioException catch (e) {
      // Network error, timeout, etc.
      // Fail-open: don't block the pipeline.
      print('[safe_browsing] Dio error calling API: ${e.message} — '
          'treating as no-threat.');
      return false;
    } catch (e) {
      // Any other unexpected error
      print('[safe_browsing] Error calling API: $e — treating as no-threat.');
      return false;
    }
  }

  bool? _getCached(String url) {
    final entry = _cache[url];
    if (entry == null) return null;

    if (DateTime.now().difference(entry.createdAt) > _cacheTtl) {
      _cache.remove(url);
      return null;
    }

    return entry.value;
  }

  void _setCached(String url, bool value) {
    _cache[url] = _CacheEntry(value: value, createdAt: DateTime.now());
  }
}

class _CacheEntry<T> {
  final T value;
  final DateTime createdAt;

  const _CacheEntry({
    required this.value,
    required this.createdAt,
  });
}
