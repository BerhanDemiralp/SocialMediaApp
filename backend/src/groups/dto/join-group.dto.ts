import { ApiProperty } from '@nestjs/swagger';
import { IsString } from 'class-validator';

export class JoinGroupDto {
  @ApiProperty({
    example: '3d72d9b2-7d5f-42f9-a5f8-d5d1c5fa96ab',
    description: 'Invite code generated when the group was created.',
  })
  @IsString()
  inviteCode!: string;
}
