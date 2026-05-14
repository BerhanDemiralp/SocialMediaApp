import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class SubmitAnswerDto {
  @ApiProperty({
    example: 'I had coffee with an old friend.',
    description: 'Answer text for today\'s daily question.',
  })
  @IsString()
  answerText!: string;
}
