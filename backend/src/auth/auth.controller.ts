import {
  Controller,
  Post,
  Body,
  Headers,
  UnauthorizedException,
  UseGuards,
  Request,
} from '@nestjs/common';
import { Request as ExpressRequest } from 'express';
import { AuthService } from './auth.service';
import { AuthGuard } from './guards/auth.guard';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Controller('auth')
export class AuthController {
  constructor(private authService: AuthService) {}

  @Post('register')
  async register(@Body() registerDto: RegisterDto) {
    return this.authService.register(registerDto);
  }

  @Post('login')
  async login(@Body() loginDto: LoginDto) {
    return this.authService.login(loginDto);
  }

  @Post('sync')
  @UseGuards(AuthGuard)
  async syncCurrentUser(
    @Request() req: ExpressRequest & {
      user?: {
        id: string;
        email: string;
        username: string;
        avatar_url: string | null;
      };
    },
  ) {
    return { user: req.user };
  }

  @Post('logout')
  async logout(@Headers('authorization') authHeader: string) {
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      throw new UnauthorizedException('No token provided');
    }
    // Currently Supabase signOut is session-based on the server side,
    // but we still validate the presence of a bearer token at the edge.
    return this.authService.logout();
  }
}
