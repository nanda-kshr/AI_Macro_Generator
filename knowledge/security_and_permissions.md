---
type: concept
title: Security, Permissions & Safety Gates
description: Security boundary definition, Android permission model, and human-in-the-loop approval workflows for device automation.
resource: https://github.com/nanda-kshr/AI_Macro_Generator
tags:
  - security
  - permissions
  - android-manifest
  - human-in-the-loop
  - okf
timestamp: 2026-08-18
---

# Security, Permissions & Safety Gates

Mobile automation systems interface directly with device hardware, requiring strict safety validation and human-in-the-loop review.

## Android Permissions Matrix

| Capability | Android Permission | Grant Type | Behavior if Missing |
| :--- | :--- | :--- | :--- |
| **Do Not Disturb (DND)** | `android.permission.ACCESS_NOTIFICATION_POLICY` | Special App Access | Automatically launches `Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS`. |
| **Silent / Vibrate Ringer** | N/A (Standard Audio Manager) | Normal | Managed via `AudioManager.ringerMode`. |
| **Countdown Timer** | `com.android.alarm.permission.SET_ALARM` | Normal | Runs in-app and posts notification. |
| **Notifications** | `android.permission.POST_NOTIFICATIONS` | Runtime (Android 13+) | Shows status alerts in notification center. |
| **Messaging / SMS** | `android.permission.SEND_SMS` | Dangerous / High-Risk | Requires explicit confirmation gate in review modal. |

## Human-in-the-Loop Approval Model

The system **never** executes natural language commands automatically without user validation:

1. **Safety Validator (`validateWorkflow`)**:
   - Inspects generated Intermediate Representation (IR).
   - Flags missing permissions with warning banners.
   - Detects destructive or outbound actions (`send_message`, financial, or system reset).
2. **Review Sheet**:
   - Presents a visual breakdown of each action and required permissions.
   - Requires explicit tap on **Approve & Run** before native execution begins.
