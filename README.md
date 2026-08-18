# AI Macro Generator

AI Macro Generator is an intelligent smartphone automation system that allows users to create complex phone workflows using natural language.

Instead of manually configuring triggers, conditions, and actions, users simply describe what they want their phone to do. The system interprets the intent, converts it into a structured workflow, validates the requested actions, and executes the approved workflow through supported Android capabilities.

> Tell your phone what you want done, not how to do it.

## Problem

Existing smartphone automation tools require users to understand automation concepts such as:

* Triggers
* Conditions
* Actions
* App integrations
* Permissions
* Execution rules

This makes multi-step automation powerful but difficult to configure.

AI Macro Generator removes much of this complexity by allowing users to express automation as natural language.

## Example

A user can say:

> When I reach college, turn on silent mode, open my timetable, message Rahul that I've arrived, and start a 50-minute timer.

The system converts the request into:

```text
Trigger:
  Arrive at college

Actions:
  1. Enable silent mode
  2. Open timetable
  3. Message Rahul
  4. Start a 50-minute timer
```

The generated workflow is presented to the user for review and approval before execution.

## How It Works

```text
Natural Language Command
          |
          v
    Intent Understanding
          |
          v
    Workflow Generation
          |
          v
    Structured Workflow
          |
          v
  Validation & Permissions
          |
          v
      User Approval
          |
          v
   Android Execution Layer
          |
          v
    Phone Actions
```

The LLM is responsible for understanding intent and generating a constrained workflow representation.

The application, rather than the LLM, is responsible for validating and executing actions.

This separation improves reliability and provides a safer architecture for smartphone automation.

## Core Architecture

### 1. Natural Language Interface

Users provide commands through text or voice.

Example:

```text
When I get home, turn off silent mode and remind me to call Mom.
```

### 2. AI Workflow Planner

The AI identifies:

* Trigger
* Actions
* Parameters
* Entities
* Timing
* Dependencies between actions

### 3. Structured Workflow

The generated workflow is represented using a constrained schema rather than arbitrary executable code.

Example:

```json
{
  "trigger": {
    "type": "location_arrival",
    "location": "Home"
  },
  "actions": [
    {
      "type": "sound_mode",
      "mode": "normal"
    },
    {
      "type": "notification",
      "title": "Reminder",
      "message": "Call Mom"
    }
  ]
}
```

### 4. Validation Layer

Before execution, the workflow is checked for:

* Supported actions
* Valid parameters
* Required permissions
* Missing information
* Potentially consequential operations

### 5. Approval Layer

Users can review the generated workflow before execution.

This provides transparency and prevents the AI from directly performing unintended actions.

### 6. Android Execution Layer

Approved actions are mapped to supported Android and OS capabilities through dedicated action adapters.

## MVP Scope

The initial MVP intentionally focuses on a limited set of reliable capabilities rather than attempting unrestricted control of the entire Android ecosystem.

Planned capabilities include:

* Location-based triggers
* Time-based triggers
* Opening supported applications
* Sound mode and Do Not Disturb controls
* Timers
* Notifications and reminders
* Calendar access
* Messaging with user approval

The architecture is designed so additional capabilities can be added without changing the core natural-language planning system.

## Example Use Cases

### Study

```text
When I start studying, enable Do Not Disturb, open my notes and start a 45-minute timer.
```

### College

```text
Every weekday at 8 AM, show my classes for today and open the first subject's notes.
```

### Travel

```text
Tomorrow morning, remind me about my flight, open my booking and show me the route to the airport.
```

### Work

```text
When I reach the office, open Gmail, Calendar and my project dashboard.
```

### Personal

```text
When I get home, turn off silent mode and remind me to call Mom.
```

## Design Principle

AI Macro Generator is built around a simple principle:

```text
Human intention
       |
       v
AI understanding
       |
       v
Structured workflow
       |
       v
Validation
       |
       v
Human approval
       |
       v
Phone execution
```

The AI should plan actions, not have unrestricted control over the device.

## Why This Approach

A direct LLM-to-device architecture would make the system difficult to reason about and potentially unreliable.

Instead, AI Macro Generator treats natural-language automation as a compilation problem:

```text
Natural Language
       |
       v
Intent Parser
       |
       v
Workflow Intermediate Representation
       |
       v
Validator
       |
       v
Execution Engine
```

This makes the system easier to test, extend, debug, and secure.

## Project Status

This project is currently being developed as a hackathon prototype.

The initial focus is:

1. Natural-language workflow generation
2. Constrained workflow schema
3. Workflow validation
4. User approval interface
5. Android action execution
6. Reliable demonstration of multi-step automation

## Team

Our team has experience across hackathons, backend engineering, open-source development, and real-world product delivery.

* Winner of Smart India Hackathon (SIH) 2025 at the National Level
* Backend leadership across multiple projects under MuLearn Foundations
* 96 GitHub repositories
* 5+ freelance projects currently live

## Future Vision

The long-term goal is to create a natural-language interface for controlling smartphone workflows.

Instead of learning how a particular automation system works, users should be able to communicate their intent directly.

```text
"I want this to happen."

        becomes

"Here is the workflow required to make it happen."
```

AI Macro Generator aims to make smartphone automation accessible to anyone who can describe what they want.

## AI Agent Guidelines & Knowledge Base (Google OKF)

This repository separates agent operational rules from domain knowledge using the **[Google Open Knowledge Format (OKF)](https://github.com/GoogleCloudPlatform/knowledge-catalog/blob/main/okf/SPEC.md)**:

- **[agent.md](file:///Users/nandakishore/Development/personals/ai_macro_generator/agent.md)**: Rulebook defining how AI agents must act, code standards, and workflows. Directs agents to the knowledge bundle.
- **[`knowledge/`](file:///Users/nandakishore/Development/personals/ai_macro_generator/knowledge/index.md)**: OKF knowledge base directory containing structured documentation.

### OKF Knowledge Storage Convention

All domain knowledge files placed inside [`knowledge/`](file:///Users/nandakishore/Development/personals/ai_macro_generator/knowledge/index.md) adhere to OKF with structured YAML frontmatter:

```yaml
---
type: <concept | reference | guide>
title: <Document Title>
description: <One-line summary of content>
resource: <URL or relative path reference>
tags:
  - <tag1>
  - <tag2>
timestamp: <YYYY-MM-DD>
---
```

Reserved files:
- [`knowledge/index.md`](file:///Users/nandakishore/Development/personals/ai_macro_generator/knowledge/index.md): Entry point index listing knowledge topics.

### Rules for AI Agents
1. Read **[agent.md](file:///Users/nandakishore/Development/personals/ai_macro_generator/agent.md)** for operational rules before starting work.
2. Consult **[`knowledge/`](file:///Users/nandakishore/Development/personals/ai_macro_generator/knowledge/index.md)** for domain concepts, architecture, and workflow specifications.
3. Keep all new knowledge documents inside `knowledge/` compliant with the OKF YAML frontmatter schema.
