import 'workflow_trigger.dart';
import 'workflow_action.dart';

class Workflow {
  final String id;
  final String name;
  final String description;
  final WorkflowTrigger trigger;
  final List<WorkflowAction> actions;
  final String createdAt;

  const Workflow({
    required this.id,
    required this.name,
    required this.description,
    required this.trigger,
    required this.actions,
    required this.createdAt,
  });

  factory Workflow.fromJson(Map<String, dynamic> json) {
    final actionsList = (json['actions'] as List<dynamic>?)
            ?.map((e) => WorkflowAction.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return Workflow(
      id: json['id'] as String? ?? 'macro_unknown',
      name: json['name'] as String? ?? 'Automation Macro',
      description: json['description'] as String? ?? '',
      trigger: json['trigger'] != null
          ? WorkflowTrigger.fromJson(json['trigger'] as Map<String, dynamic>)
          : const WorkflowTrigger(
              type: 'manual',
              description: 'Manual Trigger',
            ),
      actions: actionsList,
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'trigger': trigger.toJson(),
        'actions': actions.map((e) => e.toJson()).toList(),
        'createdAt': createdAt,
      };
}
