import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsString, IsOptional, IsUrl } from 'class-validator';

export class UpdateProfileDto {
  @ApiPropertyOptional({
    example: 'berhan',
    description: 'New display username.',
  })
  @IsString()
  @IsOptional()
  username?: string;

  @ApiPropertyOptional({
    example: 'https://example.com/avatar.png',
    description: 'Public avatar image URL.',
  })
  @IsUrl()
  @IsOptional()
  avatar_url?: string;
}
