import { IsDateString, IsString } from 'class-validator';

export class CreateDailyQuestionDto {
  @IsString()
  questionText!: string;

  @IsDateString()
  questionDate!: string;
}

