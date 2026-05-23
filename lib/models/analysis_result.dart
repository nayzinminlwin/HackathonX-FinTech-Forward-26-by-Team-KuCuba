class AnalysisResult {
  const AnalysisResult({
    required this.riskScore,
    required this.analysisMessage,
    this.isFallback = false,
  });

  final int riskScore;
  final String analysisMessage;
  final bool isFallback;

  bool get isUnavailable => riskScore < 0;

  factory AnalysisResult.fromApiJson(Map<String, dynamic> json) {
    final rawScore = json['risk_score'];
    final rawMessage = json['analysis_message'];

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
          rawMessage?.toString() ?? 'Analysis temporarily unavailable.',
    );
  }
}
