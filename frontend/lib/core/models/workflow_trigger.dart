class WorkflowTrigger {
  final String type;
  final String description;
  final Map<String, dynamic> parameters;

  const WorkflowTrigger({
    required this.type,
    required this.description,
    this.parameters = const {},
  });

  factory WorkflowTrigger.fromJson(Map<String, dynamic> json) {
    return WorkflowTrigger(
      type: json['type'] as String? ?? 'manual',
      description: json['description'] as String? ?? 'Manual trigger',
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'description': description,
        'parameters': parameters,
      };
}
