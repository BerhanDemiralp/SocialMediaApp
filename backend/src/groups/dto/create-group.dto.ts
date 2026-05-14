import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CreateGroupDto {
  @ApiProperty({
    example: 'Close Friends',
    minLength: 1,
    description: 'Group name.',
  })
  @IsString()
  @MinLength(1)
  name!: string;
}
