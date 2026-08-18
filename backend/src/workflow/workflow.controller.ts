import {
  Body,
  Controller,
  Get,
  Post,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { WorkflowService } from './workflow.service';
import { LlmService } from '../llm/llm.service';
import { GenerateWorkflowDto } from './dto/generate-workflow.dto';
import { WorkflowResponseDto } from './dto/workflow-response.dto';

@Controller('api/workflow')
export class WorkflowController {
  constructor(
    private readonly workflowService: WorkflowService,
    private readonly llmService: LlmService,
  ) {}

  @Post('generate')
  @UsePipes(new ValidationPipe({ transform: true, whitelist: true }))
  async generate(
    @Body() dto: GenerateWorkflowDto,
  ): Promise<WorkflowResponseDto> {
    return await this.workflowService.generateWorkflow(dto);
  }

  @Get('providers')
  async getProviders() {
    const providers = await this.llmService.listProviders();
    return {
      success: true,
      defaultProvider: this.llmService.getDefaultProvider(),
      providers,
    };
  }

  @Get('logs')
  getLogs() {
    const logs = this.workflowService.getLogs();
    return {
      success: true,
      count: logs.length,
      logs,
    };
  }
}
