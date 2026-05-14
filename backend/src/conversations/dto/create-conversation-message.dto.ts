import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class CreateConversationMessageDto {
  @ApiProperty({
    example: 'Hey, how is your day going?',
    description: 'Message content to send to the conversation.',
  })
  @IsString()
  content!: string;
}
