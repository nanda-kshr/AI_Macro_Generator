import 'package:flutter_test/flutter_test.dart';
import 'package:ai_macro_generator/main.dart';
import 'package:ai_macro_generator/core/models/workflow.dart';
import 'package:ai_macro_generator/core/models/workflow_response.dart';

void main() {
  testWidgets('App renders Home Screen title and prompt input', (WidgetTester tester) async {
    await tester.pumpWidget(const AiMacroApp());

    expect(find.text('Macros'), findsOneWidget);
    expect(find.text('Generate'), findsOneWidget);
    expect(find.text('Suggestions'), findsOneWidget);
  });

  test('Workflow JSON deserialization works correctly', () {
    final json = {
      'success': true,
      'workflow': {
        'id': 'test_123',
        'name': 'Study Mode',
        'description': 'Enable DND and set timer',
        'trigger': {
          'type': 'location',
          'description': 'Arrived at Library',
          'parameters': {'location': 'Library'},
        },
        'actions': [
          {
            'type': 'sound_mode',
            'title': 'Enable DND',
            'parameters': {'mode': 'dnd'},
            'requiredPermissions': ['android.permission.ACCESS_NOTIFICATION_POLICY'],
          },
          {
            'type': 'timer',
            'title': '45 min Timer',
            'parameters': {'durationMinutes': 45},
          }
        ],
        'createdAt': '2026-08-18T12:00:00Z',
      },
      'validation': {
        'isValid': true,
        'warnings': [],
        'missingPermissions': ['android.permission.ACCESS_NOTIFICATION_POLICY'],
        'highRiskActions': [],
      },
      'debug': {
        'provider': 'ollama',
        'model': 'gemma3:270m',
        'durationMs': 150,
        'rawResponse': '{}',
        'timestamp': '2026-08-18T12:00:00Z',
      }
    };

    final response = WorkflowResponse.fromJson(json);
    expect(response.success, true);
    expect(response.workflow.name, 'Study Mode');
    expect(response.workflow.actions.length, 2);
    expect(response.workflow.actions[0].type, 'sound_mode');
    expect(response.debug.provider, 'ollama');
    expect(response.debug.model, 'gemma3:270m');
  });
}
