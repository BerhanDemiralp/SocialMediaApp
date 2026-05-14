import { ApiProperty } from '@nestjs/swagger';
import { IsEmail, IsString, MinLength } from 'class-validator';

export class RegisterDto {
  @ApiProperty({
    example: 'user@example.com',
    description: 'User email address.',
  })
  @IsEmail()
  email: string;

  @ApiProperty({
    example: 'password123',
    minLength: 8,
    description: 'User password. Must be at least 8 characters.',
  })
  @IsString()
  @MinLength(8)
  password: string;

  @ApiProperty({
    example: 'berhan',
    description: 'Unique username shown in the app.',
  })
  @IsString()
  username: string;
}
