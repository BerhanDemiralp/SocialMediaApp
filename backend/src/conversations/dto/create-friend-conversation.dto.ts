import { IsString } from 'class-validator';

export class CreateFriendConversationDto {
  @IsString()
  friendId!: string;
}

