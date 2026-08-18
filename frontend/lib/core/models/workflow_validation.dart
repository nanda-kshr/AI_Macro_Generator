class WorkflowValidation {
  final bool isValid;
  final List<String> warnings;
  final List<String> missingPermissions;
  final List<String> highRiskActions;

  const WorkflowValidation({
    required this.isValid,
    this.warnings = const [],
    this.missingPermissions = const [],
    this.highRiskActions = const [],
  });

  factory WorkflowValidation.fromJson(Map<String, dynamic> json) {
    return WorkflowValidation(
      isValid: json['isValid'] as bool? ?? true,
      warnings: (json['warnings'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      missingPermissions: (json['missingPermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      highRiskActions: (json['highRiskActions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
