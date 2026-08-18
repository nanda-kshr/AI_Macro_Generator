---
type: concept
title: Workflow Pipeline & Execution Model
description: Detailed specification of practical triggers, Intermediate Representation (IR), native Android execution, and timed auto-reset flows.
resource: https://github.com/nanda-kshr/AI_Macro_Generator
tags:
  - workflow
  - execution
  - triggers
  - dnd-timer
  - platform-channel
  - okf
timestamp: 2026-08-18
---

# Workflow Pipeline & Execution Model

The system compiles natural language prompts into a deterministic, typed Intermediate Representation (IR) that executes natively on Android.

## Practical Trigger System

Instead of battery-draining and ambiguous GPS location triggers, the system prioritizes zero-friction, reliable triggers:

| Trigger Type | Identifier | Example Parameters | Description |
| :--- | :--- | :--- | :--- |
| **Instant Intent** | `manual` | `{}` | One-tap execution directly from the app or widget. |
| **Wi-Fi Network** | `wifi` | `{"ssid": "Campus-WiFi"}` | Fires when connected to a specific Wi-Fi network. |
| **Power State** | `charging` | `{"state": "plugged_in"}` | Fires when the device starts charging (e.g. at night). |
| **Schedule** | `time` | `{"time": "08:30"}` | Fires at scheduled clock times or recurring weekdays. |
| **App State** | `app_open` | `{"appName": "Spotify"}` | Fires when a specific application is launched. |

## Intermediate Representation (IR) Actions

- **`sound_mode`**: `{ "mode": "dnd" | "silent" | "vibrate" | "normal", "durationMinutes"?: number }`
- **`timer`**: `{ "durationMinutes": number, "label": string }`
- **`open_app`**: `{ "appName": string, "packageName"?: string }`
- **`notification`**: `{ "title": string, "message": string }`
- **`send_message`**: `{ "recipient": string, "message": string }` (Flagged as high-risk)

## Execution & Auto-Reset Lifecycle

1. **Prompt Compilation**: Ollama (`gemma3:270m`) or cloud LLM generates typed JSON.
2. **Permission Check & Safety Gate**: High-risk actions (SMS) and missing permissions (`ACCESS_NOTIFICATION_POLICY`) are flagged.
3. **Approval**: User reviews action steps and taps **Approve & Run**.
4. **Native OS Execution**:
   - `MainActivity.kt` toggles Do Not Disturb and starts in-app countdown.
   - User remains inside the app with a live `45:00` countdown card.
5. **Timed Reversion**:
   - When the duration expires, Android `Handler` / background task automatically restores normal sound mode (`INTERRUPTION_FILTER_ALL` / `RINGER_MODE_NORMAL`) and fires a completion notification.
