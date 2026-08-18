---
type: concept
title: LLM Adapters & SLM Optimization
description: Implementation details of the pluggable LLM adapter interface, Small Language Model (SLM) optimization for Ollama gemma3:270m, and JSON recovery strategies.
resource: https://github.com/nanda-kshr/AI_Macro_Generator
tags:
  - llm-adapter
  - ollama
  - gemma3
  - slm
  - json-sanitizer
  - okf
timestamp: 2026-08-18
---

# LLM Adapters & SLM Optimization

AI Macro Generator utilizes a decoupled adapter pattern (`ILlmAdapter`) to support multiple AI inference backends seamlessly.

## Adapter Architecture

All providers implement the `ILlmAdapter` contract defined in `backend/src/llm/llm.interface.ts`:

```typescript
export interface ILlmAdapter {
  readonly providerName: string;
  isAvailable(): boolean;
  generate(options: LlmGenerationOptions): Promise<LlmGenerationResult>;
}
```

### Supported Adapters

1. **OllamaAdapter (`ollama`)**:
   - Default Model: `gemma3:270m`.
   - Endpoint: `http://localhost:11434/api/chat`.
   - Payload Config: `{ stream: false, format: 'json', options: { temperature: 0.1 } }`.
2. **GeminiAdapter (`gemini`)**:
   - Default Model: `gemini-1.5-flash`.
   - Uses `@google/genai` with `GEMINI_API_KEY`.
3. **OpenRouterAdapter (`openrouter`)**:
   - Default Model: `meta-llama/llama-3.2-3b-instruct:free`.
   - Uses OpenAI-compatible API with `OPENROUTER_API_KEY`.

## SLM (Small Language Model) Recovery Strategies

Small local models like `gemma3:270m` can produce slightly imperfect JSON syntax. The compiler enforces a 3-layer parsing fallback:

1. **Markdown Fence Stripping**: Extracts payload enclosed in ` ```json ... ``` ` or ` ``` ... ``` `.
2. **Type Notation Sanitization**: Removes TypeScript pipe types (e.g. `"silent" | "vibrate"`) and JSON comments.
3. **Heuristic Keyword Extractor**: If parsing fails completely, an intent regex extractor analyzes triggers (Wi-Fi, charging, time) and actions (sound mode, timers, apps) directly from prompt keywords.
