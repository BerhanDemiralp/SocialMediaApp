import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class GrantWriteExceptionDto {
  @ApiPropertyOptional({
    example: '0c0f9e74-f3c8-4b34-9654-3f7890d53c9d',
    description:
      'Optional user id that receives write access. If omitted, the exception is conversation-wide.',
  })
  @IsOptional()
  @IsString()
  grantedToId?: string;
}
