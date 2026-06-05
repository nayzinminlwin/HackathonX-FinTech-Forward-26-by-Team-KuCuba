import 'package:flutter/foundation.dart';

import '../models/analysis_result.dart';
import '../services/api_service.dart';

enum AnalysisState { idle, loading, complete, error }

class AnalysisProvider extends ChangeNotifier {
  AnalysisProvider(this._apiService);

  final AnalysisApiService _apiService;

  AnalysisState _state = AnalysisState.idle;
  AnalysisResult? _result;
  String? _errorMessage;

  AnalysisState get state => _state;
  AnalysisResult? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _state == AnalysisState.loading;

  Future<void> analyze(String textPayload) async {
    final trimmed = textPayload.trim();
    if (trimmed.isEmpty) {
      return;
    }

    _state = AnalysisState.loading;
    _result = null;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _apiService.analyze(trimmed);
      _result = result;
      _state = AnalysisState.complete;
    } on AnalysisUnavailableException catch (e) {
      _state = AnalysisState.error;
      _errorMessage = e.message;
    } catch (_) {
      _state = AnalysisState.error;
      _errorMessage = 'Could not analyze. Please try again.';
    }

    notifyListeners();
  }

  void reset() {
    _state = AnalysisState.idle;
    _result = null;
    _errorMessage = null;
    notifyListeners();
  }
}
