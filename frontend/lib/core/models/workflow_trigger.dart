enum TriggerType {
  time,
  location,
  manual,
  appOpen,
  unknown,
}

class WorkflowTrigger {
  final TriggerType type;
  final String description;
  final Map<String, dynamic> parameters;

  const WorkflowTrigger({
    required this.type,
    required this.description,
    this.parameters = const {},
  });

  factory WorkflowTrigger.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] as String?)?.toLowerCase() ?? 'manual';
    TriggerType type;
    switch (typeStr) {
      case 'time':
      case 'time_based':
        type = TriggerType.time;
        break;
      case 'location':
      case 'location_arrival':
      case 'location_departure':
        type = TriggerType.location;
        break;
      case 'app_open':
        type = TriggerType.appOpen;
        break;
      case 'manual':
      default:
        type = TriggerType.manual;
    }

    return WorkflowTrigger(
      type: type,
      description: json['description'] as String? ?? 'Trigger: $typeStr',
      parameters: json['parameters'] as Map<String, dynamic>? ??
          (json..remove('type')..remove('description')),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'description': description,
      'parameters': parameters,
    };
  }
}
