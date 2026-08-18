import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/workflow_response.dart';

class LlmProviderInfo {
  final String name;
  final bool isDefault;
  final bool available;

  const LlmProviderInfo({
    required this.name,
    required this.isDefault,
    required this.available,
  });

  factory LlmProviderInfo.fromJson(Map<String, dynamic> json) {
    return LlmProviderInfo(
      name: json['name'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      available: json['available'] as bool? ?? false,
    );
  }
}

class WorkflowApiService {
  final String _baseUrl;

  WorkflowApiService({String? baseUrl})
      : _baseUrl = baseUrl ?? ApiConfig.defaultBaseUrl;

  Future<WorkflowResponse> generateWorkflow({
    required String prompt,
    String? provider,
    String? model,
  }) async {
    final url = Uri.parse('$_baseUrl/api/workflow/generate');
    final payload = {
      'prompt': prompt,
      if (provider != null) 'provider': provider,
      if (model != null) 'model': model,
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return WorkflowResponse.fromJson(data);
      } else {
        String errorMsg = 'Failed to generate workflow (${response.statusCode})';
        try {
          final errBody = jsonDecode(response.body);
          if (errBody is Map && errBody['message'] != null) {
            errorMsg = errBody['message'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      if (e.toString().contains('Connection refused') ||
          e.toString().contains('Failed host lookup')) {
        throw Exception(
          'Cannot connect to backend at $_baseUrl. Please ensure the NestJS server is running on port 3000.',
        );
      }
      rethrow;
    }
  }

  Future<List<LlmProviderInfo>> fetchProviders() async {
    final url = Uri.parse('$_baseUrl/api/workflow/providers');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final list = (data['providers'] as List<dynamic>?)
                ?.map((e) => LlmProviderInfo.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [];
        return list;
      }
    } catch (_) {}
    return [
      const LlmProviderInfo(name: 'ollama', isDefault: true, available: true),
      const LlmProviderInfo(name: 'gemini', isDefault: false, available: false),
      const LlmProviderInfo(name: 'openrouter', isDefault: false, available: false),
    ];
  }

  Future<List<dynamic>> fetchLogs() async {
    final url = Uri.parse('$_baseUrl/api/workflow/logs');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return (data['logs'] as List<dynamic>?) ?? [];
      }
    } catch (_) {}
    return [];
  }
}
