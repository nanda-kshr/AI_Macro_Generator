import 'package:flutter/material.dart';
import '../../core/models/workflow_response.dart';
import '../../core/models/workflow_action.dart';
import '../../core/execution/native_executor.dart';
import '../logs/ai_response_log_sheet.dart';

class WorkflowPreviewSheet extends StatefulWidget {
  final WorkflowResponse workflowResponse;
  final VoidCallback? onExecute;

  const WorkflowPreviewSheet({
    super.key,
    required this.workflowResponse,
    this.onExecute,
  });

  @override
  State<WorkflowPreviewSheet> createState() => _WorkflowPreviewSheetState();
}

class _WorkflowPreviewSheetState extends State<WorkflowPreviewSheet> {
  bool _isExecuting = false;
  bool _isExecuted = false;
  String _currentStepLabel = '';

  void _runWorkflow() async {
    setState(() {
      _isExecuting = true;
      _currentStepLabel = 'Initializing actions...';
    });

    final actions = widget.workflowResponse.workflow.actions;
    for (int i = 0; i < actions.length; i++) {
      final action = actions[i];
      if (mounted) {
        setState(() {
          _currentStepLabel = 'Running step ${i + 1}/${actions.length}: ${action.title}...';
        });
      }
      await NativeExecutor.executeAction(action);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (mounted) {
      setState(() {
        _isExecuting = false;
        _isExecuted = true;
      });
      widget.onExecute?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final workflow = widget.workflowResponse.workflow;
    final validation = widget.workflowResponse.validation;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    workflow.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => SizedBox(
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: AiResponseLogSheet(
                          debugInfo: widget.workflowResponse.debug,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF222734) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.terminal_rounded,
                          size: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Log',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (workflow.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                workflow.description,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 16),

            // Trigger Section
            _buildTriggerCard(context, workflow.trigger.type, workflow.trigger.description, isDark),

            const SizedBox(height: 16),
            Text(
              'Actions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),

            ...List.generate(
              workflow.actions.length,
              (index) => _buildActionTile(context, index + 1, workflow.actions[index], isDark),
            ),

            if (validation.missingPermissions.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Requires: ${validation.missingPermissions.map((p) => p.split('.').last).join(', ')}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            if (_isExecuting && _currentStepLabel.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222734) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _currentStepLabel,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Action Buttons
            if (_isExecuted) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Automation Active',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB),
                        ),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _isExecuting ? null : _runWorkflow,
                      style: FilledButton.styleFrom(
                        backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                        foregroundColor: isDark ? const Color(0xFF111827) : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: _isExecuting
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text(
                              'Approve & Run',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTriggerCard(BuildContext context, String triggerType, String triggerDesc, bool isDark) {
    IconData icon = Icons.touch_app_rounded;
    String badge = 'MANUAL TRIGGER';

    switch (triggerType) {
      case 'wifi':
        icon = Icons.wifi_rounded;
        badge = 'WI-FI TRIGGER';
        break;
      case 'charging':
        icon = Icons.battery_charging_full_rounded;
        badge = 'CHARGING TRIGGER';
        break;
      case 'time':
        icon = Icons.schedule_rounded;
        badge = 'TIME TRIGGER';
        break;
      case 'app_open':
        icon = Icons.apps_rounded;
        badge = 'APP OPEN TRIGGER';
        break;
      default:
        icon = Icons.touch_app_rounded;
        badge = 'INSTANT RUN';
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C212D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badge,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  triggerDesc,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, int step, WorkflowAction action, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C212D) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2D3748) : const Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$step',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              action.title,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
