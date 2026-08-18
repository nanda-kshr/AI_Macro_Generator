import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { ILlmAdapter, LlmGenerationOptions, LlmGenerationResult } from '../llm.interface';

@Injectable()
export class OpenRouterAdapter implements ILlmAdapter {
  readonly providerName = 'openrouter';
  private readonly logger = new Logger(OpenRouterAdapter.name);

  constructor(private readonly configService: ConfigService) {}

  private get apiKey(): string {
    return this.configService.get<string>('OPENROUTER_API_KEY') || '';
  }

  private get defaultModel(): string {
    return (
      this.configService.get<string>('OPENROUTER_MODEL') ||
      'google/gemma-3-27b-it:free'
    );
  }

  async isAvailable(): Promise<boolean> {
    return Boolean(this.apiKey && this.apiKey.trim().length > 0);
  }

  async generate(options: LlmGenerationOptions): Promise<LlmGenerationResult> {
    if (!this.apiKey) {
      throw new Error(
        'OpenRouter API key is not configured. Please set OPENROUTER_API_KEY in .env',
      );
    }

    const model = options.model || this.defaultModel;
    const url = 'https://openrouter.ai/api/v1/chat/completions';
    const startTime = Date.now();

    this.logger.log(`Calling OpenRouter [model: ${model}]...`);

    try {
      const messages: Array<{ role: string; content: string }> = [];
      if (options.systemPrompt) {
        messages.push({ role: 'system', content: options.systemPrompt });
      }
      messages.push({ role: 'user', content: options.prompt });

      const payload = {
        model,
        messages,
        temperature: options.temperature ?? 0.1,
      };

      const response = await axios.post(url, payload, {
        timeout: 60000,
        headers: {
          Authorization: `Bearer ${this.apiKey}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://github.com/nanda-kshr/AI_Macro_Generator',
          'X-Title': 'AI Macro Generator',
        },
      });

      const durationMs = Date.now() - startTime;
      const rawText =
        response.data?.choices?.[0]?.message?.content || '';

      this.logger.log(
        `OpenRouter returned response (${rawText.length} chars) in ${durationMs}ms`,
      );

      return {
        rawResponse: rawText,
        provider: this.providerName,
        model,
        durationMs,
        metadata: {
          usage: response.data?.usage,
        },
      };
    } catch (error: any) {
      const durationMs = Date.now() - startTime;
      this.logger.error(
        `OpenRouter generation failed: ${error.message}`,
        error.stack,
      );
      throw new Error(
        `OpenRouter request failed: ${error.response?.data?.error?.message || error.message}`,
      );
    }
  }
}
