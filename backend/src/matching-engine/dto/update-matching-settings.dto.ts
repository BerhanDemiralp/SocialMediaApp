import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsInt, IsOptional, IsString, Min } from 'class-validator';

export class UpdateMatchingSettingsDto {
  @ApiPropertyOptional({
    example: '19:00',
    description: 'Daily matching time in HH:mm local time format.',
  })
  @IsOptional()
  @IsString()
  dailyTimeLocal?: string;

  @ApiPropertyOptional({
    example: 'Europe/Istanbul',
    description: 'IANA timezone used for daily matching.',
  })
  @IsOptional()
  @IsString()
  timezone?: string;

  @ApiPropertyOptional({
    example: true,
    description: 'Whether automatic matching is enabled.',
  })
  @IsOptional()
  @IsBoolean()
  enabled?: boolean;

  @ApiPropertyOptional({
    example: 30,
    minimum: 1,
    description: 'Minutes after activation before sending reminders.',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  reminderAfterMinutes?: number;

  @ApiPropertyOptional({
    example: 60,
    minimum: 1,
    description: 'Minutes that a moment remains active.',
  })
  @IsOptional()
  @IsInt()
  @Min(1)
  activeDurationMinutes?: number;
}
