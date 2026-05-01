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

    let user = await this.prismaService.users.findUnique({
      where: { id: data.user.id },
    });

    if (!user) {
      user = await this.prismaService.users.create({
        data: {
          id: data.user.id,
          email: data.user.email ?? '',
          username: await this.buildAvailableFallbackUsername(data.user),
        },
      });
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

    const supaUser = data.user;

    if (!supaUser) {
      throw new UnauthorizedException('User not found for token');
    }

    // Ensure there is a corresponding local user row in Postgres.
    let user = await this.prismaService.users.findUnique({
      where: { id: supaUser.id },
    });

    if (!user) {
      user = await this.prismaService.users.create({
        data: {
          id: supaUser.id,
          email: supaUser.email ?? '',
          username: await this.buildAvailableFallbackUsername(supaUser),
        },
      });
    }

    // Controllers and gateways expect at least an `id` field on request.user / client.user.
    return {
      id: user.id,
      email: user.email,
      username: user.username,
      avatar_url: user.avatar_url,
    };
  }

  private async buildAvailableFallbackUsername(user: {
    id: string;
    email?: string | null;
    user_metadata?: Record<string, unknown> | null;
  }) {
    const base = this.buildFallbackUsernameBase(user);
    const existing = await this.prismaService.users.findUnique({
      where: { username: base },
    });

    if (!existing) {
      return base;
    }

    return `${base}_${user.id.slice(0, 6)}`;
  }

  private buildFallbackUsernameBase(user: {
    email?: string | null;
    user_metadata?: Record<string, unknown> | null;
  }) {
    const rawBase =
      user.user_metadata?.['username']?.toString() ?? user.email?.split('@')[0] ?? 'user';
    const base = rawBase
      .toLowerCase()
      .replace(/[^a-z0-9_]/g, '_')
      .replace(/_+/g, '_')
      .replace(/^_+|_+$/g, '')
      .slice(0, 24);

    return base || 'user';
  }
}
