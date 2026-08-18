import { IsNotEmpty, IsOptional, IsString, IsObject } from 'class-validator';

export class GenerateWorkflowDto {
  @IsString()
  @IsNotEmpty({ message: 'Natural language prompt is required' })
  prompt: string;

  @IsString()
  @IsOptional()
  provider?: string;

  @IsString()
  @IsOptional()
  model?: string;

  @IsObject()
  @IsOptional()
  context?: Record<string, any>;
}
