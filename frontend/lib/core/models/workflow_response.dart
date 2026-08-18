import 'workflow.dart';
import 'workflow_validation.dart';
import 'llm_debug_info.dart';

class WorkflowResponse {
  final bool success;
  final Workflow workflow;
  final WorkflowValidation validation;
  final LlmDebugInfo debug;

  const WorkflowResponse({
    required this.success,
    required this.workflow,
    required this.validation,
    required this.debug,
  });

  factory WorkflowResponse.fromJson(Map<String, dynamic> json) {
    return WorkflowResponse(
      success: json['success'] as bool? ?? false,
      workflow: Workflow.fromJson(json['workflow'] as Map<String, dynamic>),
      validation: WorkflowValidation.fromJson(
          json['validation'] as Map<String, dynamic>? ?? {}),
      debug: LlmDebugInfo.fromJson(json['debug'] as Map<String, dynamic>? ?? {}),
    );
  }
}
