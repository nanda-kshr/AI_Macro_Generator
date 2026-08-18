import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import axios from 'axios';
import { ILlmAdapter, LlmGenerationOptions, LlmGenerationResult } from '../llm.interface';

@Injectable()
export class GeminiAdapter implements ILlmAdapter {
  readonly providerName = 'gemini';
  private readonly logger = new Logger(GeminiAdapter.name);

  constructor(private readonly configService: ConfigService) {}

  private get apiKey(): string {
    return this.configService.get<string>('GEMINI_API_KEY') || '';
  }

  private get defaultModel(): string {
    return (
      this.configService.get<string>('GEMINI_MODEL') || 'gemini-1.5-flash'
    );
  }

  async isAvailable(): Promise<boolean> {
    return Boolean(this.apiKey && this.apiKey.trim().length > 0);
  }

  async generate(options: LlmGenerationOptions): Promise<LlmGenerationResult> {
    if (!this.apiKey) {
      throw new Error(
        'Gemini API key is not configured. Please set GEMINI_API_KEY in .env',
      );
    }

    const model = options.model || this.defaultModel;
    const url = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${this.apiKey}`;
    const startTime = Date.now();

    this.logger.log(`Calling Gemini API [model: ${model}]...`);

    try {
      const contents: any[] = [];
      if (options.systemPrompt) {
        contents.push({
          role: 'user',
          parts: [{ text: `SYSTEM INSTRUCTIONS:\n${options.systemPrompt}` }],
        });
        contents.push({
          role: 'model',
          parts: [{ text: 'Understood. I will strictly follow these instructions and output format.' }],
        });
      }

      contents.push({
        role: 'user',
        parts: [{ text: options.prompt }],
      });

      const payload = {
        contents,
        generationConfig: {
          temperature: options.temperature ?? 0.1,
          responseMimeType: 'application/json',
        },
      };

      const response = await axios.post(url, payload, {
        timeout: 60000,
        headers: { 'Content-Type': 'application/json' },
      });

      const durationMs = Date.now() - startTime;
      const rawText =
        response.data?.candidates?.[0]?.content?.parts?.[0]?.text || '';

      this.logger.log(
        `Gemini returned response (${rawText.length} chars) in ${durationMs}ms`,
      );

      return {
        rawResponse: rawText,
        provider: this.providerName,
        model,
        durationMs,
        metadata: {
          usageMetadata: response.data?.usageMetadata,
        },
      };
    } catch (error: any) {
      const durationMs = Date.now() - startTime;
      this.logger.error(
        `Gemini generation failed: ${error.message}`,
        error.stack,
      );
      throw new Error(
        `Gemini request failed: ${error.response?.data?.error?.message || error.message}`,
      );
    }
  }
}
