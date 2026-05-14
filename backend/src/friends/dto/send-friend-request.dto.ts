import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsUUID } from 'class-validator';

export class SendFriendRequestDto {
  @ApiProperty({
    example: '0c0f9e74-f3c8-4b34-9654-3f7890d53c9d',
    format: 'uuid',
    description: 'User id that will receive the friend request.',
  })
  @IsString()
  @IsUUID()
  targetUserId!: string;
}
