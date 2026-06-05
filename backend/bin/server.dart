import 'dart:convert';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';
import 'package:dotenv/dotenv.dart';
import 'package:kucuba_backend/handlers/analyze_handler.dart';
import 'package:kucuba_backend/services/safe_browsing.dart';
import 'package:kucuba_backend/services/gemini_service.dart';

/// CORS middleware that allows Flutter dev (any origin) to call the backend.
Middleware corsMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      // Handle preflight OPTIONS requests
      if (request.method == 'OPTIONS') {
        return Response.ok('', headers: _corsHeaders);
      }

      final response = await innerHandler(request);
      return response.change(headers: _corsHeaders);
    };
  };
}

const _corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type, x-app-secret',
};

const _appSecretHeaderName = 'x-app-secret';
const _expectedAppSecret = 'my_custom_project_key_123';

Middleware appSecretMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      if (request.method == 'OPTIONS') {
        return innerHandler(request);
      }

      final providedSecret = request.headers[_appSecretHeaderName];
      if (providedSecret != _expectedAppSecret) {
        return Response.forbidden(
          jsonEncode({
            'error': 'Forbidden',
            'analysis_message': 'App authentication failed.',
          }),
          headers: {'Content-Type': 'application/json'},
        );
      }

      return innerHandler(request);
    };
  };
}

void main() async {
  // --- Load environment ---
  final processEnv = Platform.environment;
  final envFile = File('.env');
  DotEnv? dotEnv;
  if (envFile.existsSync()) {
    dotEnv = DotEnv()..load(['.env']);
  } else {
    print('[server] No .env file found — using process environment.');
  }

  String envValue(String key, {String defaultValue = ''}) {
    final fileValue = dotEnv?.getOrElse(key, () => '');
    if (fileValue != null && fileValue.isNotEmpty) return fileValue;
    return processEnv[key] ?? defaultValue;
  }

  final geminiKey = envValue('GEMINI_API_KEY');
  final safeBrowsingKey = envValue('SAFE_BROWSING_API_KEY');
  final geminiModel = envValue(
    'GEMINI_MODEL',
    defaultValue: GeminiService.defaultModelName,
  );
  final port = int.tryParse(envValue('PORT', defaultValue: '8080')) ?? 8080;

  print(
      '[server] GEMINI_API_KEY loaded: ${geminiKey.isNotEmpty ? "yes" : "EMPTY"}');
  print(
      '[server] SAFE_BROWSING_API_KEY loaded: ${safeBrowsingKey.isNotEmpty ? "yes" : "EMPTY"}');
  print('[server] GEMINI_MODEL: $geminiModel');

  // --- Services ---
  final safeBrowsing = SafeBrowsing(apiKey: safeBrowsingKey);

  GeminiService? geminiService;
  if (geminiKey.isNotEmpty) {
    geminiService = GeminiService(
      apiKey: geminiKey,
      modelName: geminiModel,
    );
    print('[server] GeminiService initialised with model $geminiModel.');
  } else {
    print(
        '[server] WARNING: GEMINI_API_KEY is empty — Gemini analysis disabled.');
  }

  // --- Router: single route POST /analyze ---
  final analyzeHandler = AnalyzeHandler(
    safeBrowsing: safeBrowsing,
    geminiService: geminiService,
  );
  final router = Router()..post('/analyze', analyzeHandler.handle);

  // --- Pipeline: logging + CORS + router ---
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsMiddleware())
      .addMiddleware(appSecretMiddleware())
      .addHandler(router.call);

  // --- Start server on the Cloud Run PORT, defaulting to 8080 locally ---
  final server = await shelf_io.serve(handler, '0.0.0.0', port);
  print(
      '[server] KuCuba backend listening on http://${server.address.host}:${server.port}');
  print(
      '[server] Phase 1 complete: URL extraction + Safe Browsing + Gemini pipeline active.');
}
