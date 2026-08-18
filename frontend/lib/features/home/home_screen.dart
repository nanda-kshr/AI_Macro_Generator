import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api/workflow_api_service.dart';
import '../../core/config/api_config.dart';
import '../../core/models/workflow_response.dart';
import '../../core/models/workflow.dart';
import '../../core/models/workflow_action.dart';
import '../../core/models/llm_debug_info.dart';
import '../../core/execution/native_executor.dart';
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

  // Live in-app macro execution state
  Workflow? _activeRunningWorkflow;
  int _remainingSeconds = 0;
  int _totalDurationSeconds = 0;
  Timer? _countdownTimer;

  final List<String> _examplePrompts = [
    'When I start studying, enable Do Not Disturb and start a 45-minute timer.',
    'When connected to Campus-WiFi, turn on silent mode and open Timetable.',
    'When phone is charging at night, enable Do Not Disturb and set a reminder to wake up early.',
    'Every weekday at 8 AM, check calendar for today and open Notes.',
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

  LlmDebugInfo? _lastDebugInfo;

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
        setState(() {
          _isLoading = false;
          _lastDebugInfo = response.debug;
        });
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

  void _startInAppMacro(Workflow workflow) {
    // Find duration from timer or sound_mode action
    int durationMinutes = 0;
    for (final action in workflow.actions) {
      final dur = action.parameters['durationMinutes'];
      if (dur != null) {
        final parsed = dur is int ? dur : int.tryParse(dur.toString());
        if (parsed != null && parsed > durationMinutes) {
          durationMinutes = parsed;
        }
      }
    }

    if (durationMinutes > 0) {
      _countdownTimer?.cancel();
      setState(() {
        _activeRunningWorkflow = workflow;
        _totalDurationSeconds = durationMinutes * 60;
        _remainingSeconds = _totalDurationSeconds;
      });

      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        if (_remainingSeconds > 1) {
          setState(() => _remainingSeconds--);
        } else {
          timer.cancel();
          _stopActiveMacro(completedNaturally: true);
        }
      });
    }
  }

  void _stopActiveMacro({bool completedNaturally = false}) {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    
    // Restore normal sound mode natively
    NativeExecutor.executeAction(WorkflowAction(
      type: 'sound_mode',
      title: 'Restore Normal Mode',
      parameters: {'mode': 'normal'},
    ));

    if (mounted) {
      setState(() {
        _activeRunningWorkflow = null;
        _remainingSeconds = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            completedNaturally
                ? 'Macro completed: Timer ended & Normal mode restored.'
                : 'Macro cancelled: Normal mode restored.',
          ),
          backgroundColor: completedNaturally ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _promptController.dispose();
    super.dispose();
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
            _startInAppMacro(response.workflow);
          },
        ),
      ),
    );
  }

  void _showServerSettingsDialog() {
    final controller = TextEditingController(text: ApiConfig.defaultBaseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.wifi, color: Colors.blueAccent),
            SizedBox(width: 8),
            Text('Server IP Config', style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Backend API URL (phone & host machine on same Wi-Fi):',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'http://172.19.25.190:3001',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ApiConfig.customBaseUrl = controller.text.trim();
              Navigator.pop(ctx);
              _loadProviders();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Updated backend URL to ${ApiConfig.defaultBaseUrl}')),
              );
            },
            child: const Text('Save & Reconnect'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(
          'Macros',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: -0.5,
            color: theme.colorScheme.onSurface,
          ),
        ),
        actions: [
          _buildProviderDropdown(isDark),
          const SizedBox(width: 4),
          if (_lastDebugInfo != null)
            IconButton(
              icon: Icon(
                Icons.terminal_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              tooltip: 'AI Response Log',
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (ctx) => AiResponseLogSheet(debugInfo: _lastDebugInfo!),
                );
              },
            ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Server Settings',
            onPressed: _showServerSettingsDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_activeRunningWorkflow != null) ...[
              _buildLiveRunningCard(theme, isDark),
              const SizedBox(height: 20),
            ],

            // Input Card
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161922) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE5E7EB),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _promptController,
                    maxLines: 3,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                    decoration: InputDecoration(
                      hintText: 'Describe an automation in plain English...',
                      hintStyle: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          _selectedProvider == 'ollama' ? 'gemma3:270m' : _selectedProvider,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: _isLoading ? null : _generateMacro,
                        style: FilledButton.styleFrom(
                          backgroundColor: isDark ? Colors.white : const Color(0xFF111827),
                          foregroundColor: isDark ? const Color(0xFF111827) : Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.black : Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Generate',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(Icons.arrow_forward_rounded, size: 14),
                                ],
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
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.redAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(fontSize: 12, color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),
            Text(
              'Suggestions',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _examplePrompts.map((example) {
                return InkWell(
                  onTap: () => _promptController.text = example,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF161922) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE5E7EB),
                      ),
                    ),
                    child: Text(
                      example,
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Created Automations',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (_savedMacros.isNotEmpty)
                  Text(
                    '${_savedMacros.length}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            if (_savedMacros.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF161922) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Center(
                  child: Text(
                    'No automations created yet.',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...List.generate(
                _savedMacros.length,
                (index) => _buildMacroCard(_savedMacros[index], isDark),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProviderDropdown(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedProvider,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onChanged: (val) {
            if (val != null) setState(() => _selectedProvider = val);
          },
          selectedItemBuilder: (context) => [
            const Text('Ollama', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Text('Gemini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            const Text('OpenRouter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
          items: const [
            DropdownMenuItem(
              value: 'ollama',
              child: Text('Ollama (gemma3:270m)', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'gemini',
              child: Text('Gemini API', style: TextStyle(fontSize: 12)),
            ),
            DropdownMenuItem(
              value: 'openrouter',
              child: Text('OpenRouter', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroCard(Workflow macro, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF262C3A) : const Color(0xFFE5E7EB),
        ),
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
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'SAVED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          if (macro.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              macro.description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: macro.actions.map((act) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF222734) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  act.title,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRunningCard(ThemeData theme, bool isDark) {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    final timeFormatted =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    final progress = _totalDurationSeconds > 0
        ? (_totalDurationSeconds - _remainingSeconds) / _totalDurationSeconds
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161922) : const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2D3748) : const Color(0xFF1F2937),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'IN PROGRESS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'DND ON',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.orangeAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _activeRunningWorkflow?.name ?? 'Active Workflow',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                timeFormatted,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'remaining',
                style: TextStyle(fontSize: 12, color: Colors.white60),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
              minHeight: 3,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _stopActiveMacro(completedNaturally: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text(
                'Stop Macro',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
