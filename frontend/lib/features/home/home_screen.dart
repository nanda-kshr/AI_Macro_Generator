import 'package:flutter/material.dart';
import '../../core/api/workflow_api_service.dart';
import '../../core/models/workflow_response.dart';
import '../../core/models/workflow.dart';
import '../workflow/workflow_preview_sheet.dart';
import '../logs/ai_response_log_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _promptController = TextEditingController();
  final WorkflowApiService _apiService = WorkflowApiService();

  String _selectedProvider = 'ollama';
  List<LlmProviderInfo> _providers = [];
  bool _isLoading = false;
  String? _errorMessage;

  final List<Workflow> _savedMacros = [];

  final List<String> _examplePrompts = [
    'When I start studying, enable Do Not Disturb and start a 45-minute timer.',
    'When I reach college, turn on silent mode, open my timetable, and message Rahul.',
    'Every weekday at 8 AM, check calendar for today and open Notes.',
    'When I get home, turn off silent mode and remind me to call Mom.',
  ];

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    final list = await _apiService.fetchProviders();
    if (mounted) {
      setState(() {
        _providers = list;
        if (list.any((p) => p.name == 'ollama')) {
          _selectedProvider = 'ollama';
        } else if (list.isNotEmpty) {
          _selectedProvider = list.first.name;
        }
      });
    }
  }

  Future<void> _generateMacro() async {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.generateWorkflow(
        prompt: prompt,
        provider: _selectedProvider,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        _showReviewSheet(response);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  void _showReviewSheet(WorkflowResponse response) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: WorkflowPreviewSheet(
          workflowResponse: response,
          onExecute: () {
            setState(() {
              _savedMacros.insert(0, response.workflow);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text(
              'AI Macro Generator',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          _buildProviderDropdown(),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subtitle banner
            Text(
              'Tell your phone what you want done, not how to do it.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),

            // Input card
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Describe your automation in plain English...',
                      border: InputBorder.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Model: ${_selectedProvider == 'ollama' ? 'gemma3:270m' : _selectedProvider}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _isLoading ? null : _generateMacro,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, size: 16),
                        label: Text(_isLoading ? 'Compiling...' : 'Generate Macro'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Text(
              'Example Prompts:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examplePrompts.map((example) {
                return ActionChip(
                  label: Text(
                    example,
                    style: const TextStyle(fontSize: 12),
                  ),
                  avatar: const Icon(Icons.bolt, size: 14),
                  onPressed: () {
                    _promptController.text = example;
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Active & Approved Macros',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                if (_savedMacros.isNotEmpty)
                  Text(
                    '${_savedMacros.length} active',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_savedMacros.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.smart_toy_outlined,
                      size: 40,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No macros created yet.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Type a prompt above or click an example to generate your first automation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ] else ...[
              ...List.generate(
                _savedMacros.length,
                (index) => _buildMacroCard(_savedMacros[index]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProviderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProvider,
          icon: const Icon(Icons.arrow_drop_down, size: 18),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onChanged: (val) {
            if (val != null) setState(() => _selectedProvider = val);
          },
          items: const [
            DropdownMenuItem(
              value: 'ollama',
              child: Row(
                children: [
                  Icon(Icons.memory, size: 14, color: Colors.teal),
                  SizedBox(width: 6),
                  Text('Ollama (gemma3:270m)'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'gemini',
              child: Row(
                children: [
                  Icon(Icons.cloud, size: 14, color: Colors.blue),
                  SizedBox(width: 6),
                  Text('Gemini API'),
                ],
              ),
            ),
            DropdownMenuItem(
              value: 'openrouter',
              child: Row(
                children: [
                  Icon(Icons.hub, size: 14, color: Colors.orange),
                  SizedBox(width: 6),
                  Text('OpenRouter'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(Workflow macro) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  macro.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            macro.description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            children: macro.actions.map((act) {
              return Chip(
                label: Text(act.title, style: const TextStyle(fontSize: 10)),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
