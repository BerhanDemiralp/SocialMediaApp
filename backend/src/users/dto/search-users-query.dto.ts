import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Min } from 'class-validator';

export class SearchUsersQueryDto {
  @ApiProperty({
    example: 'ber',
    description: 'Username search text.',
  })
  @IsString()
  query!: string;

  @ApiPropertyOptional({
    example: 20,
    minimum: 1,
    description: 'Maximum number of users to return.',
  })
  @IsOptional()
  @Type(() => Number)
  @IsInt()
  @Min(1)
  limit?: number;
}
