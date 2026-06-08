import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({
    example: 'berhan',
    description: 'New display username.',
  })
  @IsString()
  @IsOptional()
  username?: string;

  @ApiPropertyOptional({
    example: 'preset:teal',
    description: 'Public avatar image URL or a built-in avatar preset key.',
  })
  @IsString()
  @IsOptional()
  avatar_url?: string;
}
