import 'package:flutter/foundation.dart';

/// Tracks app statistics: total scans and threats blocked.
class StatsProvider extends ChangeNotifier {
  int _totalScans = 0;
  int _threatsBlocked = 0;

  int get totalScans => _totalScans;
  int get threatsBlocked => _threatsBlocked;

  /// Records a completed analysis.
  /// [riskScore] determines if it counts as a threat (≥ 50 = threat).
  void recordAnalysis(int riskScore) {
    _totalScans++;
    if (riskScore >= 50) {
      _threatsBlocked++;
    }
    notifyListeners();
  }

  /// Resets statistics (for testing/demo).
  void reset() {
    _totalScans = 0;
    _threatsBlocked = 0;
    notifyListeners();
  }
}
