import { ApiProperty } from '@nestjs/swagger';
import { IsDateString, IsString } from 'class-validator';

export class CreateDailyQuestionDto {
  @ApiProperty({
    example: 'What made you smile today?',
    description: 'Daily question text.',
  })
  @IsString()
  questionText!: string;

  @ApiProperty({
    example: '2026-05-14',
    format: 'date',
    description: 'Date assigned to the daily question.',
  })
  @IsDateString()
  questionDate!: string;
}
