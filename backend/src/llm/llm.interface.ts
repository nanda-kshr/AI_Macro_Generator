export interface LlmGenerationOptions {
  prompt: string;
  systemPrompt?: string;
  temperature?: number;
  model?: string;
}

export interface LlmGenerationResult {
  rawResponse: string;
  provider: string;
  model: string;
  durationMs: number;
  metadata?: Record<string, any>;
}

export interface ILlmAdapter {
  readonly providerName: string;
  generate(options: LlmGenerationOptions): Promise<LlmGenerationResult>;
  isAvailable(): Promise<boolean>;
}
