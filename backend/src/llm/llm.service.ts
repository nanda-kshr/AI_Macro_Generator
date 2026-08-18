import { Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ILlmAdapter, LlmGenerationOptions, LlmGenerationResult } from './llm.interface';
import { OllamaAdapter } from './adapters/ollama.adapter';
import { GeminiAdapter } from './adapters/gemini.adapter';
import { OpenRouterAdapter } from './adapters/openrouter.adapter';

@Injectable()
export class LlmService {
  private readonly logger = new Logger(LlmService.name);
  private readonly adapters = new Map<string, ILlmAdapter>();

  constructor(
    private readonly configService: ConfigService,
    private readonly ollamaAdapter: OllamaAdapter,
    private readonly geminiAdapter: GeminiAdapter,
    private readonly openRouterAdapter: OpenRouterAdapter,
  ) {
    this.registerAdapter(this.ollamaAdapter);
    this.registerAdapter(this.geminiAdapter);
    this.registerAdapter(this.openRouterAdapter);
  }

  private registerAdapter(adapter: ILlmAdapter) {
    this.adapters.set(adapter.providerName.toLowerCase(), adapter);
  }

  getDefaultProvider(): string {
    return (
      this.configService.get<string>('DEFAULT_LLM_PROVIDER') || 'ollama'
    ).toLowerCase();
  }

  getAdapter(providerName?: string): ILlmAdapter {
    const target = (providerName || this.getDefaultProvider()).toLowerCase();
    const adapter = this.adapters.get(target);
    if (!adapter) {
      const available = Array.from(this.adapters.keys()).join(', ');
      throw new NotFoundException(
        `LLM provider '${target}' not found. Available providers: ${available}`,
      );
    }
    return adapter;
  }

  async listProviders(): Promise<
    Array<{
      name: string;
      isDefault: boolean;
      available: boolean;
    }>
  > {
    const defaultProvider = this.getDefaultProvider();
    const results: Array<{
      name: string;
      isDefault: boolean;
      available: boolean;
    }> = [];

    for (const [name, adapter] of this.adapters.entries()) {
      const available = await adapter.isAvailable();
      results.push({
        name,
        isDefault: name === defaultProvider,
        available,
      });
    }

    return results;
  }

  async generate(
    options: LlmGenerationOptions,
    providerName?: string,
  ): Promise<LlmGenerationResult> {
    const adapter = this.getAdapter(providerName);
    this.logger.log(`Executing LLM generation via '${adapter.providerName}'...`);
    return await adapter.generate(options);
  }
}
