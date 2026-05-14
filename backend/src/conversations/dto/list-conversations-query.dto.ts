import { ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class ListConversationsQueryDto {
  @ApiPropertyOptional({
    example: 20,
    minimum: 1,
    description: 'Maximum number of conversations to return.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;

  @ApiPropertyOptional({
    example: '2bd25d41-cb06-4f7f-9e83-7b46e2c55999',
    description: 'Conversation id cursor for pagination.',
  })
  @IsOptional()
  @IsString()
  cursor?: string;

  @ApiPropertyOptional({
    example: 'friend',
    enum: ['friend', 'group_pair', 'group'],
    description: 'Optional conversation type filter.',
  })
  @IsOptional()
  @IsString()
  type?: string;
}
