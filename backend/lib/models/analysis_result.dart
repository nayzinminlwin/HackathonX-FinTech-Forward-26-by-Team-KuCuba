/// Data model for the analysis response.
///
/// Mirrors the API contract:
///   {"risk_score": <int 1-100>, "analysis_message": "<string>"}
///
/// Error sentinel: risk_score -1 with standard unavailable message.
class AnalysisResult {
  final int riskScore;
  final String analysisMessage;

  const AnalysisResult({
    required this.riskScore,
    required this.analysisMessage,
  });

  /// Creates an error sentinel response.
  factory AnalysisResult.error() => const AnalysisResult(
        riskScore: -1,
        analysisMessage: 'Analysis temporarily unavailable.',
      );

  /// Converts this result to the JSON map for the HTTP response body.
  Map<String, dynamic> toJson() => {
        'risk_score': riskScore,
        'analysis_message': analysisMessage,
      };

  /// Creates an [AnalysisResult] from a decoded JSON map.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      riskScore: json['risk_score'] as int,
      analysisMessage: json['analysis_message'] as String,
    );
  }
}
