import {
  Injectable,
  InternalServerErrorException,
  Logger,
} from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';
import { LlmService } from '../llm/llm.service';
import { GenerateWorkflowDto } from './dto/generate-workflow.dto';
import {
  ExecutionLogEntry,
  LlmDebugDto,
  WorkflowActionDto,
  WorkflowDto,
  WorkflowResponseDto,
  WorkflowTriggerDto,
  WorkflowValidationDto,
} from './dto/workflow-response.dto';

@Injectable()
export class WorkflowService {
  private readonly logger = new Logger(WorkflowService.name);
  private readonly recentLogs: ExecutionLogEntry[] = [];
  private readonly maxLogs = 50;
  private readonly logDir = path.join(process.cwd(), 'logs');
  private readonly logFilePath = path.join(process.cwd(), 'logs', 'ai_responses.log');

  constructor(private readonly llmService: LlmService) {
    try {
      if (!fs.existsSync(this.logDir)) {
        fs.mkdirSync(this.logDir, { recursive: true });
      }
    } catch (_) {}
  }

  private readonly systemPrompt = `You are an AI Smartphone Macro & Automation Planner.
Convert the user natural language command into a single JSON object with "name", "description", "trigger", and "actions".

ALLOWED TRIGGER TYPES:
- "manual": {} (Instant execution / User action)
- "time": { "time": "08:00", "days": ["Monday", "Tuesday"] }
- "wifi": { "ssid": "<WiFi network name>" } (Connected to specific Wi-Fi)
- "charging": { "state": "plugged_in" | "unplugged" }
- "app_open": { "appName": "<name>" }

ALLOWED ACTION TYPES:
- "sound_mode": { "mode": "silent" | "vibrate" | "normal" | "dnd", "durationMinutes"?: <number> }
- "open_app": { "appName": "<name>" }
- "timer": { "durationMinutes": <number>, "label": "<label>" }
- "notification": { "title": "<title>", "message": "<msg>" }
- "send_message": { "recipient": "<name>", "message": "<msg>" }
- "calendar_view": { "date": "today" }

EXAMPLE:
User: "When connected to College-WiFi, turn on silent mode and open Timetable"
JSON:
{
  "name": "College Wi-Fi Routine",
  "description": "Enable silent mode and open timetable when connected to College-WiFi",
  "trigger": { "type": "wifi", "description": "Connected to College-WiFi", "parameters": { "ssid": "College-WiFi" } },
  "actions": [
    { "type": "sound_mode", "title": "Enable Silent Mode", "parameters": { "mode": "silent" } },
    { "type": "open_app", "title": "Open Timetable", "parameters": { "appName": "Timetable" } }
  ]
}

EXAMPLE 2:
User: "When I start studying, enable Do Not Disturb and start 45 minute timer"
JSON:
{
  "name": "Study Session",
  "description": "Turn on DND for 45 minutes and start study timer",
  "trigger": { "type": "manual", "description": "Start study session", "parameters": {} },
  "actions": [
    { "type": "sound_mode", "title": "Enable Do Not Disturb (45 mins)", "parameters": { "mode": "dnd", "durationMinutes": 45 } },
    { "type": "timer", "title": "Start 45 min timer", "parameters": { "durationMinutes": 45, "label": "Study" } }
  ]
}

EXAMPLE 3:
User: "When phone is charging at night, enable Do Not Disturb and set a reminder to wake up early"
JSON:
{
  "name": "Bedtime Charging Routine",
  "description": "Enable DND and set reminder when plugged in",
  "trigger": { "type": "charging", "description": "Phone plugged in / charging", "parameters": { "state": "plugged_in" } },
  "actions": [
    { "type": "sound_mode", "title": "Enable Do Not Disturb", "parameters": { "mode": "dnd" } },
    { "type": "notification", "title": "Wake Up Reminder", "parameters": { "title": "Alarm", "message": "Wake up early for classes" } }
  ]
}

Return ONLY valid JSON.`;

  private logEntry(entry: ExecutionLogEntry) {
    this.recentLogs.unshift(entry);
    if (this.recentLogs.length > this.maxLogs) {
      this.recentLogs.pop();
    }
  }

  private writeLogToFile(entry: ExecutionLogEntry) {
    try {
      const line = JSON.stringify(entry) + '\n';
      fs.appendFileSync(this.logFilePath, line, 'utf8');
    } catch (err: any) {
      this.logger.warn(`Failed to write log to file: ${err.message}`);
    }
  }

  getLogs(): ExecutionLogEntry[] {
    return this.recentLogs;
  }

  async generateWorkflow(
    dto: GenerateWorkflowDto,
  ): Promise<WorkflowResponseDto> {
    const startTime = Date.now();
    const logId = `log_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`;
    const chosenProvider = dto.provider || this.llmService.getDefaultProvider();

    this.logger.log(`Generating workflow for prompt: "${dto.prompt}" [Provider: ${chosenProvider}]`);

    let rawResponse = '';
    let modelUsed = dto.model || 'default';
    let durationMs = 0;

    try {
      const llmResult = await this.llmService.generate(
        {
          prompt: `User Request: "${dto.prompt}"`,
          systemPrompt: this.systemPrompt,
          temperature: 0.1,
          model: dto.model,
        },
        dto.provider,
      );

      rawResponse = llmResult.rawResponse;
      modelUsed = llmResult.model;
      durationMs = llmResult.durationMs;

      // Extract and sanitize JSON
      const parsedJson = this.extractAndParseJson(rawResponse);
      const workflow = this.normalizeWorkflow(parsedJson, dto.prompt);
      const validation = this.validateWorkflow(workflow);

      const debug: LlmDebugDto = {
        provider: llmResult.provider,
        model: modelUsed,
        durationMs,
        rawResponse,
        timestamp: new Date().toISOString(),
      };

      const logRecord: ExecutionLogEntry = {
        id: logId,
        timestamp: debug.timestamp,
        prompt: dto.prompt,
        provider: llmResult.provider,
        model: modelUsed,
        durationMs,
        rawResponse,
        parsedWorkflow: workflow,
      };

      this.logEntry(logRecord);
      this.writeLogToFile(logRecord);

      // Print visible terminal debug banner
      console.log(`\n=================== [AI RESPONSE DEBUG LOG] ===================`);
      console.log(`[ID]        : ${logId}`);
      console.log(`[PROMPT]    : "${dto.prompt}"`);
      console.log(`[PROVIDER]  : ${llmResult.provider} (model: ${modelUsed})`);
      console.log(`[LATENCY]   : ${durationMs} ms`);
      console.log(`[RAW OUTPUT]:\n${rawResponse}`);
      console.log(`[PARSED IR] :\n${JSON.stringify(workflow, null, 2)}`);
      console.log(`===============================================================\n`);

      return {
        success: true,
        workflow,
        validation,
        debug,
      };
    } catch (error: any) {
      this.logger.error(`Workflow generation failed: ${error.message}`, error.stack);
      this.logEntry({
        id: logId,
        timestamp: new Date().toISOString(),
        prompt: dto.prompt,
        provider: chosenProvider,
        model: modelUsed,
        durationMs: Date.now() - startTime,
        rawResponse,
        error: error.message,
      });

      throw new InternalServerErrorException(
        `Failed to generate workflow: ${error.message}. (Raw AI response: ${rawResponse.substring(0, 200)}...)`,
      );
    }
  }

  private extractAndParseJson(raw: string): any {
    let text = raw.trim();

    // Remove markdown code fences if present (e.g. ```json ... ```)
    const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)\s*```/);
    if (fenceMatch) {
      text = fenceMatch[1].trim();
    } else {
      // Find outermost JSON object
      const start = text.indexOf('{');
      const end = text.lastIndexOf('}');
      if (start !== -1 && end !== -1 && end > start) {
        text = text.substring(start, end + 1);
      }
    }

    // Strip single-line comments // ... and multi-line /* ... */ comments
    text = text.replace(/\/\/.*$/gm, '');
    text = text.replace(/\/\*[\s\S]*?\*\//g, '');

    // Replace typescript pipe literals e.g. "time" | "location" -> "time"
    text = text.replace(/"([^"]+)"(?:\s*\|\s*"[^"]+")+/g, '"$1"');

    // Remove trailing commas before } or ]
    text = text.replace(/,\s*([\}\]])/g, '$1');

    try {
      return JSON.parse(text);
    } catch (err: any) {
      throw new Error(`JSON parsing failed: ${err.message}. Content was: ${text}`);
    }
  }

  private normalizeWorkflow(raw: any, originalPrompt: string): WorkflowDto {
    const id = `macro_${Date.now()}_${Math.random().toString(36).substring(2, 6)}`;
    const name = raw.name || 'Custom Automation Macro';
    const description = raw.description || originalPrompt;

    const rawTrigger = raw.trigger || {};
    const trigger: WorkflowTriggerDto = {
      type: rawTrigger.type || 'manual',
      description: rawTrigger.description || `Trigger: ${rawTrigger.type || 'manual'}`,
      parameters: rawTrigger.parameters || {},
    };

    const actions: WorkflowActionDto[] = [];
    if (Array.isArray(raw.actions) && raw.actions.length > 0) {
      for (const item of raw.actions) {
        if (!item || typeof item !== 'object') continue;
        const type = item.type || 'notification';
        const title = item.title || this.deriveActionTitle(type, item.parameters || {});
        const parameters = item.parameters || {};

        const { requiredPermissions, requiresConfirmation } =
          this.deriveSecurityAttributes(type, parameters);

        actions.push({
          type,
          title,
          parameters,
          requiredPermissions,
          requiresConfirmation,
        });
      }
    } else {
      // Fallback extraction from prompt text for ultra-small models (like 270m)
      const extracted = this.extractFallbackActionsAndTrigger(originalPrompt);
      if (trigger.type === 'manual' && extracted.trigger) {
        trigger.type = extracted.trigger.type;
        trigger.description = extracted.trigger.description;
        trigger.parameters = extracted.trigger.parameters;
      }
      actions.push(...extracted.actions);
    }

    return {
      id,
      name,
      description,
      trigger,
      actions,
      createdAt: new Date().toISOString(),
    };
  }

  private deriveActionTitle(type: string, params: Record<string, any>): string {
    switch (type) {
      case 'sound_mode': {
        const modeStr = params.mode || 'normal';
        const dur = params.durationMinutes ? ` (${params.durationMinutes} mins)` : '';
        return `Set sound mode to ${modeStr}${dur}`;
      }
      case 'open_app':
        return `Open ${params.appName || 'Application'}`;
      case 'timer':
        return `Start ${params.durationMinutes || 0} min timer`;
      case 'notification':
        return `Show notification: ${params.title || 'Reminder'}`;
      case 'send_message':
        return `Send message to ${params.recipient || 'recipient'}`;
      case 'calendar_view':
        return `Check calendar for ${params.date || 'today'}`;
      default:
        return `Execute ${type}`;
    }
  }

  private extractFallbackActionsAndTrigger(prompt: string): {
    trigger?: WorkflowTriggerDto;
    actions: WorkflowActionDto[];
  } {
    const text = prompt.toLowerCase();
    const actions: WorkflowActionDto[] = [];
    let trigger: WorkflowTriggerDto | undefined;

    // Detect duration if specified in prompt (e.g. 45 min, 45-minute, 50 minutes)
    const timerMatch = text.match(/(\d+)\s*(?:-|–|\s)?(?:minute|min)/i);
    const durationMinutes = timerMatch ? parseInt(timerMatch[1], 10) : undefined;

    // Trigger detection: Wi-Fi, Charging, Time, App Open, or Manual
    if (text.includes('wifi') || text.includes('wi-fi') || text.includes('connected to')) {
      const wifiMatch = text.match(/(?:connected to|on)\s+([a-zA-Z0-9_\-\s]+?)(?:,|$|\s+turn|\s+open|\s+enable|\s+set)/i);
      const ssid = wifiMatch ? wifiMatch[1].trim() : 'Campus-WiFi';
      trigger = {
        type: 'wifi',
        description: `Connected to "${ssid}"`,
        parameters: { ssid },
      };
    } else if (text.includes('charging') || text.includes('plugged in')) {
      trigger = {
        type: 'charging',
        description: 'Phone plugged in & charging',
        parameters: { state: 'plugged_in' },
      };
    } else if (text.includes('when') && text.includes('opens')) {
      const appMatch = text.match(/when\s+([a-zA-Z0-9\s]+?)\s+opens/i);
      const app = appMatch ? appMatch[1].trim() : 'App';
      trigger = {
        type: 'app_open',
        description: `When ${app} is opened`,
        parameters: { appName: app },
      };
    } else if (text.includes('at') && (text.includes('am') || text.includes('pm') || text.includes(':'))) {
      const timeMatch = text.match(/at\s+(\d+(?::\d+)?\s*(?:am|pm)?)/i);
      trigger = {
        type: 'time',
        description: `Every day at ${timeMatch ? timeMatch[1] : 'scheduled time'}`,
        parameters: { time: timeMatch ? timeMatch[1] : '08:00' },
      };
    } else {
      trigger = {
        type: 'manual',
        description: 'Instant Intent Action',
        parameters: {},
      };
    }

    // Action 1: Sound mode / DND
    if (text.includes('silent') || text.includes('mute')) {
      const { requiredPermissions, requiresConfirmation } = this.deriveSecurityAttributes('sound_mode', { mode: 'silent' });
      actions.push({
        type: 'sound_mode',
        title: durationMinutes ? `Enable Silent Mode (${durationMinutes} mins)` : 'Enable Silent Mode',
        parameters: { mode: 'silent', ...(durationMinutes ? { durationMinutes } : {}) },
        requiredPermissions,
        requiresConfirmation,
      });
    } else if (text.includes('do not disturb') || text.includes('dnd')) {
      const { requiredPermissions, requiresConfirmation } = this.deriveSecurityAttributes('sound_mode', { mode: 'dnd' });
      actions.push({
        type: 'sound_mode',
        title: durationMinutes ? `Enable Do Not Disturb (${durationMinutes} mins)` : 'Enable Do Not Disturb',
        parameters: { mode: 'dnd', ...(durationMinutes ? { durationMinutes } : {}) },
        requiredPermissions,
        requiresConfirmation,
      });
    } else if (text.includes('normal mode') || text.includes('turn off silent')) {
      const { requiredPermissions, requiresConfirmation } = this.deriveSecurityAttributes('sound_mode', { mode: 'normal' });
      actions.push({
        type: 'sound_mode',
        title: 'Set Normal Sound Mode',
        parameters: { mode: 'normal' },
        requiredPermissions,
        requiresConfirmation,
      });
    }

    // Action 2: Open app
    if (text.includes('open')) {
      const openMatches = text.matchAll(/open\s+(?:my\s+)?([a-zA-Z0-9\s]+?)(?:,|$|\s+and|\s+start|\s+set|\s+turn|\s+message)/gi);
      for (const m of openMatches) {
        const app = m[1].trim();
        if (app.length > 1 && !app.startsWith('silent') && !app.startsWith('timer')) {
          const { requiredPermissions, requiresConfirmation } = this.deriveSecurityAttributes('open_app', { appName: app });
          actions.push({
            type: 'open_app',
            title: `Open ${app[0].toUpperCase() + app.slice(1)}`,
            parameters: { appName: app },
            requiredPermissions,
            requiresConfirmation,
          });
        }
      }
    }

    // Action 3: Timer
    if (text.includes('timer') || text.includes('minute') || text.includes('min')) {
      const timerMatch = text.match(/(\d+)\s*(?:-|–|\s)?(?:minute|min)/i);
      const minutes = timerMatch ? parseInt(timerMatch[1], 10) : 15;
      const { requiredPermissions, requiresConfirmation } = this.deriveSecurityAttributes('timer', { durationMinutes: minutes });
      actions.push({
        type: 'timer',
        title: `Start ${minutes}-minute timer`,
        parameters: { durationMinutes: minutes, label: 'Automation Timer' },
        requiredPermissions,
        requiresConfirmation,
      });
    }

    // Action 4: Message
    if (text.includes('message') || text.includes('sms') || text.includes('text')) {
      const msgMatch = text.match(/(?:message|text|sms)\s+([a-zA-Z0-9]+)/i);
      const recipient = msgMatch ? msgMatch[1] : 'Recipient';
      const { requiredPermissions, requiresConfirmation } = this.deriveSecurityAttributes('send_message', { recipient });
      actions.push({
        type: 'send_message',
        title: `Send message to ${recipient}`,
        parameters: { recipient, message: 'I have arrived.' },
        requiredPermissions,
        requiresConfirmation,
      });
    }

    // Action 5: Notification / Reminder
    if (text.includes('remind') || text.includes('notification')) {
      const remMatch = text.match(/remind(?:\s+me)?\s+(?:to\s+)?(.+?)(?:,|$|\s+and)/i);
      const note = remMatch ? remMatch[1].trim() : 'Automation Reminder';
      const { requiredPermissions, requiresConfirmation } = this.deriveSecurityAttributes('notification', { message: note });
      actions.push({
        type: 'notification',
        title: `Show reminder: ${note}`,
        parameters: { title: 'Reminder', message: note },
        requiredPermissions,
        requiresConfirmation,
      });
    }

    return { trigger, actions };
  }

  private deriveSecurityAttributes(
    type: string,
    params: Record<string, any>,
  ): { requiredPermissions: string[]; requiresConfirmation: boolean } {
    const perms: string[] = [];
    let requiresConfirmation = false;

    switch (type) {
      case 'sound_mode':
        if (params.mode === 'dnd' || params.mode === 'silent') {
          perms.push('android.permission.ACCESS_NOTIFICATION_POLICY');
        }
        break;
      case 'timer':
        perms.push('android.permission.SET_TIMER');
        break;
      case 'notification':
        perms.push('android.permission.POST_NOTIFICATIONS');
        break;
      case 'send_message':
        perms.push('android.permission.SEND_SMS');
        requiresConfirmation = true;
        break;
    }

    return { requiredPermissions: perms, requiresConfirmation };
  }

  private validateWorkflow(workflow: WorkflowDto): WorkflowValidationDto {
    const warnings: string[] = [];
    const missingPermissions = new Set<string>();
    const highRiskActions: string[] = [];

    if (!workflow.actions || workflow.actions.length === 0) {
      warnings.push('Workflow contains no actions.');
    }

    for (const action of workflow.actions) {
      if (action.requiredPermissions) {
        for (const p of action.requiredPermissions) {
          missingPermissions.add(p);
        }
      }
      if (action.requiresConfirmation) {
        highRiskActions.push(action.title);
      }
    }

    return {
      isValid: workflow.actions.length > 0,
      warnings,
      missingPermissions: Array.from(missingPermissions),
      highRiskActions,
    };
  }
}
