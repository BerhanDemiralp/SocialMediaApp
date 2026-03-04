import {
  Injectable,
  UnauthorizedException,
  BadRequestException,
} from '@nestjs/common';
import { SupabaseService } from '../supabase/supabase.service';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private supabaseService: SupabaseService,
    private prismaService: PrismaService,
  ) {}

  async register(registerDto: RegisterDto) {
    const { email, password, username } = registerDto;

    const { data, error } = await this.supabaseService.client.auth.signUp({
      email,
      password,
    });

    if (error) {
      throw new BadRequestException(error.message);
    }

    if (!data.user) {
      throw new BadRequestException('Failed to create user');
    }

    const user = await this.prismaService.users.create({
      data: {
        id: data.user.id,
        email,
        username,
      },
    });

    return {
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
      },
      session: data.session,
    };
  }

  async login(loginDto: LoginDto) {
    const { email, password } = loginDto;

    const { data, error } =
      await this.supabaseService.client.auth.signInWithPassword({
        email,
        password,
      });

    if (error) {
      throw new UnauthorizedException(error.message);
    }

    if (!data.user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const user = await this.prismaService.users.findUnique({
      where: { id: data.user.id },
    });

    if (!user) {
      throw new UnauthorizedException('User not found');
    }

    return {
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        avatar_url: user.avatar_url,
      },
      session: data.session,
    };
  }

  async logout() {
    const { error } = await this.supabaseService.client.auth.signOut();

    if (error) {
      throw new BadRequestException(error.message);
    }

    return { message: 'Logged out successfully' };
  }

  async validateToken(token: string) {
    const { data, error } =
      await this.supabaseService.client.auth.getUser(token);

    if (error) {
      throw new UnauthorizedException(error.message);
    }

    return data.user;
  }
}
