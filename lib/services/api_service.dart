import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../models/analysis_result.dart';

abstract class AnalysisApiService {
  Future<AnalysisResult> analyze(String textPayload);
}

class LiveApiService implements AnalysisApiService {
  static const Duration analysisTimeout = Duration(seconds: 12);

  LiveApiService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.backendBaseUrl,
                connectTimeout: analysisTimeout,
                receiveTimeout: analysisTimeout,
                sendTimeout: analysisTimeout,
                contentType: Headers.jsonContentType,
              ),
            );

  final Dio _dio;

  @override
  Future<AnalysisResult> analyze(String textPayload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      AppConfig.analyzeEndpoint,
      data: {'text_payload': textPayload},
    );

    if (response.statusCode != 200 || response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Analysis request failed (${response.statusCode}).',
      );
    }

    final result = AnalysisResult.fromJson(response.data!);
    if (result.isUnavailable) {
      throw AnalysisUnavailableException(result.analysisMessage);
    }

    return result;
  }
}

class AnalysisUnavailableException implements Exception {
  AnalysisUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
