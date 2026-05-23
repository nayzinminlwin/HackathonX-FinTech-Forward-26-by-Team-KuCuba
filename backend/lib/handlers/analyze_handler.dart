import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../services/link_extractor.dart';
import '../services/safe_browsing.dart';
import '../services/gemini_service.dart';
import '../services/url_expander.dart';
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
  final UrlExpander _urlExpander;

  AnalyzeHandler({
    required SafeBrowsing safeBrowsing,
    GeminiService? geminiService,
    UrlExpander? urlExpander,
  })  : _safeBrowsing = safeBrowsing,
        _geminiService = geminiService,
        _urlExpander = urlExpander ?? UrlExpander();

  /// Handles an incoming POST /analyze request.
  Future<Response> handle(Request request) async {
    final totalStopwatch = Stopwatch()..start();
    var extractMs = 0;
    var expandMs = 0;
    var safeBrowsingMs = 0;
    var geminiMs = 0;

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

      final prefersMalay = _isLikelyMalay(textPayload);

      // --- Step 1: URL extraction ---
      final extractStopwatch = Stopwatch()..start();
      final urls = LinkExtractor.extractUrls(textPayload);
      extractStopwatch.stop();
      extractMs = extractStopwatch.elapsedMilliseconds;

      final hasShortenedUrl = LinkExtractor.containsShortenedUrl(urls);
      final shortenedUrls = LinkExtractor.extractShortenedUrls(urls);
      var unresolvedShortenedUrl = false;
      final expandedUrls = <String>[];
      final urlContext = StringBuffer();

      print('[analyze] Extracted ${urls.length} URL(s), '
          '${shortenedUrls.length} shortened.');

      final expansionStopwatch = Stopwatch();
      Future<List<UrlExpansionResult>> expansionFuture = Future.value([]);
      if (shortenedUrls.isNotEmpty) {
        expansionStopwatch.start();
        expansionFuture = _urlExpander.expandAll(shortenedUrls).whenComplete(
              expansionStopwatch.stop,
            );
      }

      // --- Step 2a: Safe Browsing on original URLs while shorteners expand ---
      final safeBrowsingStopwatch = Stopwatch();
      Future<bool> originalThreatFuture = Future.value(false);
      if (urls.isNotEmpty) {
        safeBrowsingStopwatch.start();
        originalThreatFuture = _safeBrowsing.checkUrls(urls).whenComplete(
              safeBrowsingStopwatch.stop,
            );
      }

      final originalThreat = await originalThreatFuture;
      safeBrowsingMs += safeBrowsingStopwatch.elapsedMilliseconds;
      if (originalThreat) {
        print('[analyze] Safe Browsing threat detected — returning 100.');
        _logTimings(
          source: 'safe_browsing',
          totalStopwatch: totalStopwatch,
          extractMs: extractMs,
          expandMs: expandMs,
          safeBrowsingMs: safeBrowsingMs,
          geminiMs: geminiMs,
        );
        return _knownThreatResponse(prefersMalay);
      }

      final expansionResults = await expansionFuture;
      expandMs = expansionStopwatch.elapsedMilliseconds;
      for (final result in expansionResults) {
        if (!result.expanded) {
          unresolvedShortenedUrl = true;
          urlContext.writeln(
            '- A shortened URL could not be expanded; treat the hidden '
            'destination as caution evidence, not proof.',
          );
          continue;
        }

        if (result.expandedUrl != null) {
          expandedUrls.add(result.expandedUrl!);
          urlContext.writeln(
            '- A shortened URL expands to ${result.expandedUrl}.',
          );
        }
      }

      // --- Step 2b: Safe Browsing on expanded destinations only ---
      if (expandedUrls.isNotEmpty) {
        safeBrowsingStopwatch
          ..reset()
          ..start();
        final expandedThreat = await _safeBrowsing.checkUrls(expandedUrls);
        safeBrowsingStopwatch.stop();
        safeBrowsingMs += safeBrowsingStopwatch.elapsedMilliseconds;
        if (expandedThreat) {
          print('[analyze] Expanded URL threat detected — returning 100.');
          _logTimings(
            source: 'safe_browsing',
            totalStopwatch: totalStopwatch,
            extractMs: extractMs,
            expandMs: expandMs,
            safeBrowsingMs: safeBrowsingMs,
            geminiMs: geminiMs,
          );
          return _knownThreatResponse(prefersMalay);
        }
      }

      // --- Step 3: Gemini LLM analysis ---
      if (_geminiService == null) {
        print('[analyze] Gemini service not available (no API key).');
        _logTimings(
          source: 'backend',
          totalStopwatch: totalStopwatch,
          extractMs: extractMs,
          expandMs: expandMs,
          safeBrowsingMs: safeBrowsingMs,
          geminiMs: geminiMs,
        );
        return _jsonResponse(AnalysisResult.error(
          message: prefersMalay ? 'Analisis sementara tidak tersedia.' : null,
        ));
      }

      final geminiService = _geminiService;
      final geminiStopwatch = Stopwatch()..start();
      final geminiResult = await geminiService.analyzeText(
        textPayload,
        urlContext: urlContext.toString(),
      );
      geminiStopwatch.stop();
      geminiMs = geminiStopwatch.elapsedMilliseconds;

      if (geminiResult == null) {
        // Gemini call failed or returned unparseable response
        print('[analyze] Gemini returned null — using error sentinel.');
        _logTimings(
          source: 'backend',
          totalStopwatch: totalStopwatch,
          extractMs: extractMs,
          expandMs: expandMs,
          safeBrowsingMs: safeBrowsingMs,
          geminiMs: geminiMs,
        );
        return _jsonResponse(AnalysisResult.error(
          message: prefersMalay ? 'Analisis sementara tidak tersedia.' : null,
        ));
      }

      // --- Validate and clamp risk_score ---
      final rawScore = geminiResult['risk_score'];
      final rawMessage = geminiResult['analysis_message'];

      if (rawScore == null || rawMessage == null) {
        print('[analyze] Gemini response missing required fields.');
        _logTimings(
          source: 'backend',
          totalStopwatch: totalStopwatch,
          extractMs: extractMs,
          expandMs: expandMs,
          safeBrowsingMs: safeBrowsingMs,
          geminiMs: geminiMs,
        );
        return _jsonResponse(AnalysisResult.error(
          message: prefersMalay ? 'Analisis sementara tidak tersedia.' : null,
        ));
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
          _logTimings(
            source: 'backend',
            totalStopwatch: totalStopwatch,
            extractMs: extractMs,
            expandMs: expandMs,
            safeBrowsingMs: safeBrowsingMs,
            geminiMs: geminiMs,
          );
          return _jsonResponse(AnalysisResult.error(
            message: prefersMalay ? 'Analisis sementara tidak tersedia.' : null,
          ));
        }
      } else {
        print('[analyze] Unexpected risk_score type: ${rawScore.runtimeType}');
        _logTimings(
          source: 'backend',
          totalStopwatch: totalStopwatch,
          extractMs: extractMs,
          expandMs: expandMs,
          safeBrowsingMs: safeBrowsingMs,
          geminiMs: geminiMs,
        );
        return _jsonResponse(AnalysisResult.error(
          message: prefersMalay ? 'Analisis sementara tidak tersedia.' : null,
        ));
      }

      // Clamp to 1–100 range (rule.md §3.2)
      riskScore = riskScore.clamp(1, 100);
      if (hasShortenedUrl && riskScore <= 30) {
        riskScore = 31;
      }

      final analysisMessage = _analysisMessageWithUrlContext(
        rawMessage is String ? rawMessage : rawMessage.toString(),
        unresolvedShortenedUrl: unresolvedShortenedUrl,
        prefersMalay: prefersMalay,
      );

      print('[analyze] Gemini result — risk_score: $riskScore');
      _logTimings(
        source: 'gemini',
        totalStopwatch: totalStopwatch,
        extractMs: extractMs,
        expandMs: expandMs,
        safeBrowsingMs: safeBrowsingMs,
        geminiMs: geminiMs,
      );

      return _jsonResponse(AnalysisResult(
        riskScore: riskScore,
        analysisMessage: analysisMessage,
        analysisSource: 'gemini',
      ));
    } catch (e) {
      // Catch-all: never crash, never return a 5xx with no body (rule.md §3.1)
      print('[analyze] Unhandled error: $e');
      _logTimings(
        source: 'backend',
        totalStopwatch: totalStopwatch,
        extractMs: extractMs,
        expandMs: expandMs,
        safeBrowsingMs: safeBrowsingMs,
        geminiMs: geminiMs,
      );
      return _jsonResponse(AnalysisResult.error(
        message: null,
      ));
    }
  }

  /// Builds a JSON [Response] from an [AnalysisResult].
  Response _jsonResponse(AnalysisResult result) {
    return Response.ok(
      jsonEncode(result.toJson()),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Response _knownThreatResponse(bool prefersMalay) {
    return _jsonResponse(AnalysisResult(
      riskScore: 100,
      analysisMessage: prefersMalay
          ? 'Amaran: Mesej ini mengandungi pautan yang ditanda sebagai '
              'berbahaya (phishing/malware). Jangan klik pautan tersebut.'
          : 'Warning: This message contains a link flagged as '
              'malicious (phishing/malware). Do not click it.',
      analysisSource: 'safe_browsing',
    ));
  }

  void _logTimings({
    required String source,
    required Stopwatch totalStopwatch,
    required int extractMs,
    required int expandMs,
    required int safeBrowsingMs,
    required int geminiMs,
  }) {
    print('[timing] source=$source extract_ms=$extractMs '
        'expand_ms=$expandMs safe_browsing_ms=$safeBrowsingMs '
        'gemini_ms=$geminiMs total_ms=${totalStopwatch.elapsedMilliseconds}');
  }

  String _analysisMessageWithUrlContext(
    String message, {
    required bool unresolvedShortenedUrl,
    required bool prefersMalay,
  }) {
    if (!unresolvedShortenedUrl) return message;

    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('shortened') ||
        lowerMessage.contains('hidden') ||
        lowerMessage.contains('expand')) {
      return message;
    }

    return prefersMalay
        ? '$message Mesej ini juga mengandungi pautan pendek yang destinasi '
            'akhirnya tidak dapat disahkan, jadi anggap ia dengan berhati-hati.'
        : '$message The message also includes a shortened link whose final '
            'destination could not be checked, so treat it with caution.';
  }

  bool _isLikelyMalay(String text) {
    final lower = text.toLowerCase();
    const markers = [
      'saya',
      'anda',
      'awak',
      'kamu',
      'kita',
      'kami',
      'tolong',
      'sila',
      'terima',
      'kasih',
      'maaf',
      'segera',
      'sekarang',
      'boleh',
      'tidak',
      'tak',
      'jangan',
      'kerana',
      'untuk',
      'pada',
      'dari',
      'dengan',
      'ini',
      'itu',
      'sudah',
      'belum',
      'hantar',
      'hubungi',
      'pindahan',
      'bayar',
      'pembayaran',
      'menang',
      'tahniah',
      'hadiah',
      'polis',
      'lhdn',
      'bank',
      'akaun',
      'kata',
      'laluan',
      'kata laluan',
      'tac',
      'otp',
    ];

    var hits = 0;
    for (final marker in markers) {
      final pattern = marker.contains(' ')
          ? RegExp(r'\b' + RegExp.escape(marker) + r'\b')
          : RegExp(r'\b' + marker + r'\b');
      if (pattern.hasMatch(lower)) {
        hits++;
        if (hits >= 2) return true;
      }
    }

    return false;
  }
}
