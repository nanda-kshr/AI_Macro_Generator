import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { OllamaAdapter } from './adapters/ollama.adapter';
import { GeminiAdapter } from './adapters/gemini.adapter';
import { OpenRouterAdapter } from './adapters/openrouter.adapter';
import { LlmService } from './llm.service';

@Module({
  imports: [ConfigModule],
  providers: [
    OllamaAdapter,
    GeminiAdapter,
    OpenRouterAdapter,
    LlmService,
  ],
  exports: [LlmService],
})
export class LlmModule {}
