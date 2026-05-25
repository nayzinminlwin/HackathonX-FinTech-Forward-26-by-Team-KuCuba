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
    final baseUrl = AppConfig.backendBaseUrl.trim();
    if (baseUrl.isEmpty) {
      throw const AnalysisUnavailableException(
        'Backend URL is not configured. Please rebuild with API_BASE_URL.',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        AppConfig.analyzeEndpoint,
        data: {'text_payload': textPayload},
      );

      if (response.statusCode != 200 || response.data == null) {
        throw AnalysisUnavailableException(_messageFromResponse(response));
      }

      final result = AnalysisResult.fromJson(response.data!);
      if (result.isUnavailable) {
        throw AnalysisUnavailableException(result.analysisMessage);
      }

      return result;
    } on AnalysisUnavailableException {
      rethrow;
    } on DioException catch (error) {
      throw AnalysisUnavailableException(_messageFromDio(error));
    } on FormatException {
      throw const AnalysisUnavailableException(
        'Backend returned an invalid analysis response. Please try again.',
      );
    } on TypeError {
      throw const AnalysisUnavailableException(
        'Backend returned an unexpected analysis response. Please try again.',
      );
    }
  }

  String _messageFromDio(DioException error) {
    final response = error.response;
    if (response != null) {
      return _messageFromResponse(response);
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout =>
        'Could not connect to the backend. Check the server URL and try again.',
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        'The backend took too long to respond. Please try again.',
      DioExceptionType.connectionError =>
        'Could not reach the backend. Check your connection and API_BASE_URL.',
      DioExceptionType.badCertificate =>
        'Backend TLS certificate could not be verified.',
      DioExceptionType.cancel => 'Analysis request was cancelled.',
      _ => 'Could not analyze. Please try again.',
    };
  }

  String _messageFromResponse(Response<dynamic> response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final backendMessage = data['analysis_message']?.toString().trim();
      if (backendMessage != null && backendMessage.isNotEmpty) {
        return backendMessage;
      }
      final errorMessage = data['error']?.toString().trim();
      if (errorMessage != null && errorMessage.isNotEmpty) {
        return errorMessage;
      }
    }

    final statusCode = response.statusCode;
    if (statusCode == null) return 'Backend request failed. Please try again.';
    if (statusCode >= 500) {
      return 'Backend service is temporarily unavailable. Please try again.';
    }
    if (statusCode == 404) {
      return 'Backend analyze endpoint was not found. Check API_BASE_URL.';
    }
    return 'Backend request failed with HTTP $statusCode. Please try again.';
  }
}

class AnalysisUnavailableException implements Exception {
  const AnalysisUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}
