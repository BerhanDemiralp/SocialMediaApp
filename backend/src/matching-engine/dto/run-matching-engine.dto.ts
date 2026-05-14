import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString } from 'class-validator';

export class RunMatchingEngineDto {
  @ApiPropertyOptional({
    example: '19:00',
    description: 'Optional HH:mm daily time override for this run.',
  })
  @IsOptional()
  @IsString()
  dailyTimeLocal?: string;
}
