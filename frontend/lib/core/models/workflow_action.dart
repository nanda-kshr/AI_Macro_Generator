class WorkflowAction {
  final String type;
  final String title;
  final Map<String, dynamic> parameters;
  final List<String> requiredPermissions;
  final bool requiresConfirmation;

  const WorkflowAction({
    required this.type,
    required this.title,
    this.parameters = const {},
    this.requiredPermissions = const [],
    this.requiresConfirmation = false,
  });

  factory WorkflowAction.fromJson(Map<String, dynamic> json) {
    return WorkflowAction(
      type: json['type'] as String? ?? 'notification',
      title: json['title'] as String? ?? 'Action',
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      requiredPermissions: (json['requiredPermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      requiresConfirmation: json['requiresConfirmation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type,
        'title': title,
        'parameters': parameters,
        'requiredPermissions': requiredPermissions,
        'requiresConfirmation': requiresConfirmation,
      };
}
