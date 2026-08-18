import 'package:flutter/services.dart';
import '../models/workflow_action.dart';

class NativeExecutor {
  static const MethodChannel _channel =
      MethodChannel('com.example.ai_macro_generator/execution');

  static Future<bool> executeAction(WorkflowAction action) async {
    try {
      switch (action.type) {
        case 'sound_mode':
          final mode = action.parameters['mode']?.toString() ?? 'normal';
          final duration = action.parameters['durationMinutes'];
          final durationMinutes = duration is int
              ? duration
              : int.tryParse(duration?.toString() ?? '');
          final result = await _channel.invokeMethod<bool>('setSoundMode', {
            'mode': mode,
            if (durationMinutes != null) 'durationMinutes': durationMinutes,
          });
          return result ?? false;

        case 'timer':
          final duration = action.parameters['durationMinutes'];
          final minutes = duration is int
              ? duration
              : int.tryParse(duration?.toString() ?? '1') ?? 1;
          final label = action.parameters['label']?.toString() ?? action.title;
          final result = await _channel.invokeMethod<bool>('setTimer', {
            'durationMinutes': minutes,
            'label': label,
          });
          return result ?? false;

        case 'open_app':
          final appName = action.parameters['appName']?.toString() ?? '';
          final packageName = action.parameters['packageName']?.toString();
          final result = await _channel.invokeMethod<bool>('openApp', {
            'appName': appName,
            'packageName': packageName,
          });
          return result ?? false;

        case 'notification':
          final title = action.parameters['title']?.toString() ?? 'AI Macro';
          final message = action.parameters['message']?.toString() ?? action.title;
          final result = await _channel.invokeMethod<bool>('showNotification', {
            'title': title,
            'message': message,
          });
          return result ?? false;

        default:
          return true;
      }
    } on PlatformException catch (e) {
      print('Native action execution failed: ${e.message}');
      return false;
    } catch (e) {
      print('Execution error: $e');
      return false;
    }
  }

  static Future<bool> checkDndPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('checkDndPermission');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestDndPermission() async {
    try {
      await _channel.invokeMethod('requestDndPermission');
    } catch (_) {}
  }
}
