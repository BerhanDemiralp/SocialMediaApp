import { IsString, IsUUID } from 'class-validator';

export class SendFriendRequestDto {
  @IsString()
  @IsUUID()
  targetUserId!: string;
}

