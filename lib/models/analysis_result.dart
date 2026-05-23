class AnalysisResult {
  const AnalysisResult({
    required this.riskScore,
    required this.analysisMessage,
  });

  final int riskScore;
  final String analysisMessage;

  bool get isUnavailable => riskScore < 0;

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    final rawScore = json['risk_score'];
    final int score;
    if (rawScore is int) {
      score = rawScore;
    } else if (rawScore is double) {
      score = rawScore.round();
    } else if (rawScore is String) {
      score = int.tryParse(rawScore) ?? -1;
    } else {
      score = -1;
    }

    return AnalysisResult(
      riskScore: score,
      analysisMessage:
          json['analysis_message']?.toString() ??
          'Analysis temporarily unavailable.',
    );
  }
}
