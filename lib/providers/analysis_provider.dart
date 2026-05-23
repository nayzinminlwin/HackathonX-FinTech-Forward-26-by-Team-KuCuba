import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

enum AnalysisState { initial, loading, complete, error }

class AnalysisResult {
  final int riskScore;
  final String analysisMessage;
  AnalysisResult({required this.riskScore, required this.analysisMessage});

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      riskScore: json['risk_score'] ?? -1,
      analysisMessage: json['analysis_message'] ?? 'Error',
    );
  }
}

class AnalysisProvider with ChangeNotifier {
  AnalysisState _state = AnalysisState.initial;
  AnalysisResult? _result;
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'http://10.0.2.2:8080',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
    contentType: Headers.jsonContentType,
    validateStatus: (_) => true,
  ));

  AnalysisState get state => _state;
  AnalysisResult? get result => _result;

  Future<void> analyze(String text) async {
    if (text.trim().isEmpty) return;
    _state = AnalysisState.loading;
    notifyListeners();

    try {
      final response = await _dio.post('/analyze', data: {'text_payload': text});

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data is String ? jsonDecode(response.data) : response.data;
        _result = AnalysisResult.fromJson(data);
        _state = AnalysisState.complete;
      } else {
        _state = AnalysisState.error;
      }
    } catch (e) {
      _state = AnalysisState.error;
    }
    notifyListeners();
  }
}