import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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

  AnalysisState get state => _state;
  AnalysisResult? get result => _result;

  Future<void> analyze(String text) async {
    if (text.trim().isEmpty) return;
    _state = AnalysisState.loading;
    notifyListeners();

    try {
      // 10.0.2.2 is the Android Emulator IP to reach your laptop's localhost
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'text_payload': text}),
      );

      if (response.statusCode == 200) {
        _result = AnalysisResult.fromJson(jsonDecode(response.body));
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