import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class CreateFriendConversationDto {
  @ApiProperty({
    example: '0c0f9e74-f3c8-4b34-9654-3f7890d53c9d',
    description: 'Friend user id to create or reuse a conversation with.',
  })
  @IsString()
  friendId!: string;
}
