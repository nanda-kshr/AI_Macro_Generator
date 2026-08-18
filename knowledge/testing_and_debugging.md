---
type: concept
title: Testing, Debugging & Telemetry
description: Comprehensive guide for testing live over Wi-Fi, debugging local Ollama inference, and viewing telemetry logs.
resource: https://github.com/nanda-kshr/AI_Macro_Generator
tags:
  - testing
  - debugging
  - telemetry
  - wifi-debugging
  - okf
timestamp: 2026-08-18
---

# Testing, Debugging & Telemetry

This guide documents how to test, debug, and inspect LLM latency and execution telemetry across development and physical mobile environments.

## Network & Device Configuration

- **Host LAN Binding**: NestJS backend binds to `0.0.0.0:3001` (e.g. `http://172.19.25.190:3001`).
- **Flutter API Client**: Configured in `frontend/lib/core/config/api_config.dart` with an in-app dynamic IP configuration dialog.
- **Wireless ADB Deployment**:
  ```bash
  adb connect <device-ip>:<port>
  cd frontend && flutter run -d <device-ip>:<port>
  ```

## AI Telemetry & Log Inspection

1. **Persistent File Logging**:
   - Location: `backend/logs/ai_responses.log` (JSON Lines format).
   - Contains: `id`, `timestamp`, `prompt`, `provider`, `model`, `durationMs`, `rawResponse`, and `parsedWorkflow`.
2. **REST API Endpoint**:
   - `GET /api/workflow/logs` returns the 50 most recent generation records.
3. **In-App Inspector**:
   - Tap the terminal icon (`Icons.terminal_rounded`) in the AppBar or **AI Log** inside the review sheet to view raw JSON, model name, and generation latency.

## Verification Commands

- **Backend Unit Tests**:
  ```bash
  cd backend && npm test
  ```
- **Frontend Widget & Model Tests**:
  ```bash
  cd frontend && flutter test
  ```
- **Direct Backend Generation Test**:
  ```bash
  curl -s -X POST http://localhost:3001/api/workflow/generate \
    -H "Content-Type: application/json" \
    -d '{"prompt": "When I start studying, enable Do Not Disturb and start a 45-minute timer"}'
  ```
