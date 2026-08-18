import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { ILlmAdapter, LlmGenerationOptions, LlmGenerationResult } from '../llm.interface';

@Injectable()
export class OllamaAdapter implements ILlmAdapter {
  readonly providerName = 'ollama';
  private readonly logger = new Logger(OllamaAdapter.name);

  constructor(private readonly configService: ConfigService) {}

  private get baseUrl(): string {
    return (
      this.configService.get<string>('OLLAMA_BASE_URL') ||
      'http://localhost:11434'
    ).replace(/\/$/, '');
  }

  private get defaultModel(): string {
    return (
      this.configService.get<string>('OLLAMA_MODEL') || 'gemma3:270m'
    );
  }

  async isAvailable(): Promise<boolean> {
    try {
      const response = await axios.get(`${this.baseUrl}/api/tags`, {
        timeout: 2000,
      });
      return response.status === 200;
    } catch {
      return false;
    }
  }

  async generate(options: LlmGenerationOptions): Promise<LlmGenerationResult> {
    const model = options.model || this.defaultModel;
    const url = `${this.baseUrl}/api/chat`;
    const startTime = DateTrans.now();

    this.logger.log(
      `Calling Ollama /api/chat [model: ${model}]...`,
    );

    try {
      const messages: Array<{ role: string; content: string }> = [];
      if (options.systemPrompt) {
        messages.push({ role: 'system', content: options.systemPrompt });
      }
      messages.push({ role: 'user', content: options.prompt });

      const payload = {
        model,
        messages,
        format: 'json',
        stream: false,
        options: {
          temperature: options.temperature ?? 0.1,
        },
      };

      const response = await axios.post(url, payload, {
        timeout: 60000,
        headers: { 'Content-Type': 'application/json' },
      });

      const durationMs = DateTrans.now() - startTime;
      const rawText = response.data?.message?.content || '';

      this.logger.log(
        `Ollama returned response (${rawText.length} chars) in ${durationMs}ms`,
      );

      return {
        rawResponse: rawText,
        provider: this.providerName,
        model,
        durationMs,
        metadata: {
          totalDuration: response.data?.total_duration,
          evalCount: response.data?.eval_count,
        },
      };
    } catch (error: any) {
      const durationMs = DateTrans.now() - startTime;
      this.logger.error(
        `Ollama generation failed: ${error.message}`,
        error.stack,
      );
      throw new Error(
        `Ollama request failed (${model}): ${error.response?.data?.error || error.message}. Ensure Ollama is running with '${model}'.`,
      );
    }
  }
}

const DateTrans = {
  now(): number {
    return Date.now();
  },
};
