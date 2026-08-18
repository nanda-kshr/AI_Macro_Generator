---
type: concept
title: System Architecture & Design
description: Architectural overview of AI Macro Generator across Flutter UI, core compilation pipeline, and Android services.
resource: https://github.com/nanda-kshr/AI_Macro_Generator
tags:
  - architecture
  - flutter
  - android
  - system-design
timestamp: 2026-08-18
---

# System Architecture & Design

AI Macro Generator operates as a multi-tier compilation and execution system for mobile automation.

## Layered Architecture

1. **Presentation (UI Layer)**: Flutter interface for natural language prompt entry, workflow review, and execution feedback.
2. **Domain / Compiler Layer**: Intent parsing, IR generation, and rule-based validation.
3. **Execution / Native Layer**: Method channels and platform integration with Android system automation hooks.

## Platform Integration

- **Android**: Method channels for invoking device actions (settings, apps, timers, notifications).
- **Core Dart**: Pure logic decoupled from platform-specific APIs.
