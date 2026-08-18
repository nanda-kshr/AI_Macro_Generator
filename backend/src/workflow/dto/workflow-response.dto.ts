export interface WorkflowTriggerDto {
  type: 'time' | 'location' | 'manual' | 'app_open' | string;
  description: string;
  parameters: Record<string, any>;
}

export interface WorkflowActionDto {
  type:
    | 'sound_mode'
    | 'open_app'
    | 'timer'
    | 'notification'
    | 'send_message'
    | 'calendar_view'
    | string;
  title: string;
  parameters: Record<string, any>;
  requiredPermissions?: string[];
  requiresConfirmation?: boolean;
}

export interface WorkflowDto {
  id: string;
  name: string;
  description: string;
  trigger: WorkflowTriggerDto;
  actions: WorkflowActionDto[];
  createdAt: string;
}

export interface WorkflowValidationDto {
  isValid: boolean;
  warnings: string[];
  missingPermissions: string[];
  highRiskActions: string[];
}

export interface LlmDebugDto {
  provider: string;
  model: string;
  durationMs: number;
  rawResponse: string;
  timestamp: string;
}

export interface ExecutionLogEntry {
  id: string;
  timestamp: string;
  prompt: string;
  provider: string;
  model: string;
  durationMs: number;
  rawResponse: string;
  parsedWorkflow?: WorkflowDto;
  error?: string;
}

export interface WorkflowResponseDto {
  success: boolean;
  workflow: WorkflowDto;
  validation: WorkflowValidationDto;
  debug: LlmDebugDto;
}
