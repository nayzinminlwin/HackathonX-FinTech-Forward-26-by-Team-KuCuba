/// Data model for the analysis response.
///
/// Mirrors the API contract:
///   {
///     "risk_score": <int 1-100>,
///     "analysis_message": "<string>",
///     "analysis_source": "safe_browsing" | "gemini" | "backend"
///   }
///
/// Error sentinel: risk_score -1 with standard unavailable message.
class AnalysisResult {
  final int riskScore;
  final String analysisMessage;
  final String analysisSource;

  const AnalysisResult({
    required this.riskScore,
    required this.analysisMessage,
    required this.analysisSource,
  });

  /// Creates an error sentinel response.
  factory AnalysisResult.error() => const AnalysisResult(
        riskScore: -1,
        analysisMessage: 'Analysis temporarily unavailable.',
        analysisSource: 'backend',
      );

  /// Converts this result to the JSON map for the HTTP response body.
  Map<String, dynamic> toJson() => {
        'risk_score': riskScore,
        'analysis_message': analysisMessage,
        'analysis_source': analysisSource,
      };

  /// Creates an [AnalysisResult] from a decoded JSON map.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      riskScore: json['risk_score'] as int,
      analysisMessage: json['analysis_message'] as String,
      analysisSource: json['analysis_source'] as String? ?? 'backend',
    );
  }
}
