import { ApiProperty } from '@nestjs/swagger';
import { IsBoolean } from 'class-validator';

export class RespondGroupMomentFriendshipDto {
  @ApiProperty({
    example: true,
    description: 'Whether the user wants to become friends after a successful group Moment.',
  })
  @IsBoolean()
  wantsFriend!: boolean;
}
