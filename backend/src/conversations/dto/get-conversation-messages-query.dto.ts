import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class GetConversationMessagesQueryDto {
  @ApiPropertyOptional({
    example: 50,
    minimum: 1,
    description: 'Maximum number of messages to return.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;

  @ApiPropertyOptional({
    example: '9bc6da69-50f8-4652-b9a5-08d41d22fd41',
    description: 'Message id cursor for pagination.',
  })
  @IsOptional()
  @IsString()
  cursor?: string;
}
