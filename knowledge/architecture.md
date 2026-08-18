---
type: concept
title: System Architecture & Design
description: Architectural overview of AI Macro Generator across NestJS multi-adapter backend, Flutter minimalist UI, and Android native execution channels.
resource: https://github.com/nanda-kshr/AI_Macro_Generator
tags:
  - architecture
  - nestjs
  - flutter
  - android
  - llm-adapter
  - okf
timestamp: 2026-08-18
---

# System Architecture & Design

AI Macro Generator operates as a multi-tier compilation, review, and native execution system for smartphone automation.

```
┌──────────────────────────────────────────────────────────┐
│                   Flutter Frontend (UI)                  │
│   - Minimalist Design System (Monochrome Slate / Dark)   │
│   - Live In-App Timer Banner & Human-in-the-Loop Review  │
│   - In-App AI Debug Inspector                            │
└──────────────┬────────────────────────────▲──────────────┘
               │ HTTP / JSON                │ Platform Channel
               ▼                            ▼
┌──────────────────────────────┐ ┌───────────────────────────┐
│       NestJS Backend         │ │   Android Native Execution│
│ - Multi-LLM Adapter Layer    │ │ - DND / Sound Manager     │
│   (Ollama, Gemini, OpenRouter)│ │ - Timed DND Auto-Reset    │
│ - Schema Sanitizer & Fallback│ │ - Background Timer & Notif│
│ - Persistent AI Response Log │ │ - App Launcher Intents    │
└──────────────────────────────┘ └───────────────────────────┘
```

## Layered Architecture

1. **Presentation Layer (Flutter)**:
   - Minimalist, typography-first user interface.
   - Live in-app countdown banner and state management.
   - Provider switcher (`ollama`, `gemini`, `openrouter`).
   - In-app raw AI debug inspector.

2. **Compiler & Adapter Layer (NestJS Backend)**:
   - Pluggable adapter interface (`ILlmAdapter`) supporting local Ollama (`gemma3:270m`), Google Gemini, and OpenRouter.
   - JSON extraction, markdown-fence sanitizer, and heuristic fallback parsing.
   - File-based (`backend/logs/ai_responses.log`) and console debug logging.

3. **Native Execution Layer (Android Kotlin)**:
   - Flutter `MethodChannel` (`com.example.ai_macro_generator/execution`).
   - `MainActivity.kt` handles hardware sound modes, DND policy filters, timed state auto-reversion, and system app launching.
