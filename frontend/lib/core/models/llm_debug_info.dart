class LlmDebugInfo {
  final String provider;
  final String model;
  final int durationMs;
  final String rawResponse;
  final String timestamp;

  const LlmDebugInfo({
    required this.provider,
    required this.model,
    required this.durationMs,
    required this.rawResponse,
    required this.timestamp,
  });

  factory LlmDebugInfo.fromJson(Map<String, dynamic> json) {
    return LlmDebugInfo(
      provider: json['provider'] as String? ?? 'unknown',
      model: json['model'] as String? ?? 'default',
      durationMs: json['durationMs'] as int? ?? 0,
      rawResponse: json['rawResponse'] as String? ?? '',
      timestamp: json['timestamp'] as String? ?? '',
    );
  }
}
