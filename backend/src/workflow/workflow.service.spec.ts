import { Test, TestingModule } from '@nestjs/testing';
import { WorkflowService } from './workflow.service';
import { LlmService } from '../llm/llm.service';

describe('WorkflowService', () => {
  let service: WorkflowService;
  let mockLlmService: Partial<LlmService>;

  beforeEach(async () => {
    mockLlmService = {
      getDefaultProvider: jest.fn().mockReturnValue('ollama'),
      generate: jest.fn().mockResolvedValue({
        rawResponse: JSON.stringify({
          name: 'Study Routine',
          description: 'Enable DND and set timer',
          trigger: {
            type: 'manual',
            description: 'User starts study mode',
          },
          actions: [
            {
              type: 'sound_mode',
              title: 'Enable DND',
              parameters: { mode: 'dnd' },
            },
            {
              type: 'timer',
              title: '45 min Study Timer',
              parameters: { durationMinutes: 45, label: 'Study' },
            },
          ],
        }),
        provider: 'ollama',
        model: 'gemma3:270m',
        durationMs: 120,
      }),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        WorkflowService,
        { provide: LlmService, useValue: mockLlmService },
      ],
    }).compile();

    service = module.get<WorkflowService>(WorkflowService);
  });

  it('should be defined', () => {
    expect(service).toBeDefined();
  });

  it('should generate structured workflow from natural language prompt', async () => {
    const result = await service.generateWorkflow({
      prompt: 'When I start studying, enable Do Not Disturb and start 45 min timer',
    });

    expect(result.success).toBe(true);
    expect(result.workflow.name).toBe('Study Routine');
    expect(result.workflow.actions.length).toBe(2);
    expect(result.workflow.actions[0].type).toBe('sound_mode');
    expect(result.workflow.actions[1].type).toBe('timer');
    expect(result.debug.provider).toBe('ollama');
    expect(result.debug.model).toBe('gemma3:270m');
  });

  it('should handle markdown-fenced json responses from smaller models', async () => {
    mockLlmService.generate = jest.fn().mockResolvedValue({
      rawResponse: '```json\n{"name":"Arrive Home","actions":[{"type":"open_app","parameters":{"appName":"Music"}}]}\n```',
      provider: 'ollama',
      model: 'gemma3:270m',
      durationMs: 95,
    });

    const result = await service.generateWorkflow({
      prompt: 'Open music when I get home',
    });

    expect(result.success).toBe(true);
    expect(result.workflow.name).toBe('Arrive Home');
    expect(result.workflow.actions[0].type).toBe('open_app');
  });
});
