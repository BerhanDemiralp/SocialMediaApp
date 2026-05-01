import { Test, TestingModule } from '@nestjs/testing';
import { AuthService } from './auth.service';
import { SupabaseService } from '../supabase/supabase.service';
import { PrismaService } from '../prisma/prisma.service';
import { BadRequestException, UnauthorizedException } from '@nestjs/common';

describe('AuthService', () => {
  let service: AuthService;
  let supabaseService: {
    client: {
      auth: {
        signUp: jest.Mock;
        signInWithPassword: jest.Mock;
        signOut: jest.Mock;
        getUser: jest.Mock;
      };
    };
  };
  let prismaService: {
    users: {
      create: jest.Mock;
      findUnique: jest.Mock;
    };
  };

  beforeEach(async () => {
    supabaseService = {
      client: {
        auth: {
          signUp: jest.fn(),
          signInWithPassword: jest.fn(),
          signOut: jest.fn(),
          getUser: jest.fn(),
        },
      },
    };

    prismaService = {
      users: {
        create: jest.fn(),
        findUnique: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        AuthService,
        {
          provide: SupabaseService,
          useValue: supabaseService,
        },
        {
          provide: PrismaService,
          useValue: prismaService,
        },
      ],
    }).compile();

    service = module.get<AuthService>(AuthService);
  });

  describe('register', () => {
    it('should create user in Supabase and Prisma and return session', async () => {
      const registerDto = {
        email: 'user@example.com',
        password: 'password123',
        username: 'testuser',
      };

      const supabaseUser = { id: 'user-id' };
      const supabaseSession = { access_token: 'token' };

      supabaseService.client.auth.signUp.mockResolvedValue({
        data: { user: supabaseUser, session: supabaseSession },
        error: null,
      });

      prismaService.users.create.mockResolvedValue({
        id: 'user-id',
        email: registerDto.email,
        username: registerDto.username,
      });

      const result = await service.register(registerDto as any);

      expect(supabaseService.client.auth.signUp).toHaveBeenCalledWith({
        email: registerDto.email,
        password: registerDto.password,
      });
      expect(prismaService.users.create).toHaveBeenCalledWith({
        data: {
          id: supabaseUser.id,
          email: registerDto.email,
          username: registerDto.username,
        },
      });
      expect(result).toEqual({
        user: {
          id: 'user-id',
          email: registerDto.email,
          username: registerDto.username,
        },
        session: supabaseSession,
      });
    });

    it('should throw BadRequestException when Supabase returns error', async () => {
      supabaseService.client.auth.signUp.mockResolvedValue({
        data: { user: null, session: null },
        error: { message: 'Email already registered' },
      });

      await expect(
        service.register({
          email: 'user@example.com',
          password: 'password123',
          username: 'testuser',
        } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });

    it('should throw BadRequestException when Supabase user is missing', async () => {
      supabaseService.client.auth.signUp.mockResolvedValue({
        data: { user: null, session: null },
        error: null,
      });

      await expect(
        service.register({
          email: 'user@example.com',
          password: 'password123',
          username: 'testuser',
        } as any),
      ).rejects.toBeInstanceOf(BadRequestException);
    });
  });

  describe('login', () => {
    it('should authenticate user and return user with session', async () => {
      const loginDto = { email: 'user@example.com', password: 'password123' };

      const supabaseUser = { id: 'user-id' };
      const supabaseSession = { access_token: 'token' };

      supabaseService.client.auth.signInWithPassword.mockResolvedValue({
        data: { user: supabaseUser, session: supabaseSession },
        error: null,
      });

      const prismaUser = {
        id: 'user-id',
        email: loginDto.email,
        username: 'testuser',
        avatar_url: 'avatar.png',
      };

      prismaService.users.findUnique.mockResolvedValue(prismaUser);

      const result = await service.login(loginDto as any);

      expect(
        supabaseService.client.auth.signInWithPassword,
      ).toHaveBeenCalledWith(loginDto);
      expect(prismaService.users.findUnique).toHaveBeenCalledWith({
        where: { id: supabaseUser.id },
      });
      expect(result).toEqual({
        user: {
          id: prismaUser.id,
          email: prismaUser.email,
          username: prismaUser.username,
          avatar_url: prismaUser.avatar_url,
        },
        session: supabaseSession,
      });
    });

    it('should throw UnauthorizedException when Supabase returns error', async () => {
      supabaseService.client.auth.signInWithPassword.mockResolvedValue({
        data: { user: null, session: null },
        error: { message: 'invalid credentials' },
      });

      await expect(
        service.login({ email: 'user@example.com', password: 'wrong' } as any),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('should throw UnauthorizedException when Supabase user is missing', async () => {
      supabaseService.client.auth.signInWithPassword.mockResolvedValue({
        data: { user: null, session: null },
        error: null,
      });

      await expect(
        service.login({ email: 'user@example.com', password: 'wrong' } as any),
      ).rejects.toBeInstanceOf(UnauthorizedException);
    });

    it('creates local user on login when missing', async () => {
      const loginDto = { email: 'user@example.com', password: 'password123' };

      const supabaseUser = {
        id: 'user-id',
        email: loginDto.email,
        user_metadata: { username: 'testuser' },
      };
      const supabaseSession = { access_token: 'token' };

      supabaseService.client.auth.signInWithPassword.mockResolvedValue({
        data: { user: supabaseUser, session: supabaseSession },
        error: null,
      });

      prismaService.users.findUnique.mockResolvedValue(null);
      prismaService.users.create.mockResolvedValue({
        id: 'user-id',
        email: loginDto.email,
        username: 'testuser',
        avatar_url: null,
      });

      const result = await service.login(loginDto as any);

      expect(prismaService.users.create).toHaveBeenCalledWith({
        data: {
          id: 'user-id',
          email: loginDto.email,
          username: 'testuser',
        },
      });
      expect(result.user.id).toBe('user-id');
    });

    it('adds a suffix to fallback username only when it is already taken', async () => {
      const loginDto = { email: 'taken@example.com', password: 'password123' };

      const supabaseUser = {
        id: 'abcdef12-3456-7890',
        email: loginDto.email,
        user_metadata: {},
      };
      const supabaseSession = { access_token: 'token' };

      supabaseService.client.auth.signInWithPassword.mockResolvedValue({
        data: { user: supabaseUser, session: supabaseSession },
        error: null,
      });

      prismaService.users.findUnique
        .mockResolvedValueOnce(null)
        .mockResolvedValueOnce({ id: 'other-user', username: 'taken' });
      prismaService.users.create.mockResolvedValue({
        id: supabaseUser.id,
        email: loginDto.email,
        username: 'taken_abcdef',
        avatar_url: null,
      });

      await service.login(loginDto as any);

      expect(prismaService.users.create).toHaveBeenCalledWith({
        data: {
          id: supabaseUser.id,
          email: loginDto.email,
          username: 'taken_abcdef',
        },
      });
    });
  });

  describe('logout', () => {
    it('should call Supabase signOut and return success message', async () => {
      supabaseService.client.auth.signOut.mockResolvedValue({ error: null });

      const result = await service.logout();

      expect(supabaseService.client.auth.signOut).toHaveBeenCalled();
      expect(result).toEqual({ message: 'Logged out successfully' });
    });

    it('should throw BadRequestException when signOut returns error', async () => {
      supabaseService.client.auth.signOut.mockResolvedValue({
        error: { message: 'signout failed' },
      });

      await expect(service.logout()).rejects.toBeInstanceOf(
        BadRequestException,
      );
    });
  });

  describe('validateToken', () => {
    it('should return user when token is valid', async () => {
      const supaUser = { id: 'user-id', email: 'user@example.com' };
      supabaseService.client.auth.getUser.mockResolvedValue({
        data: { user: supaUser },
        error: null,
      });

      prismaService.users.findUnique.mockResolvedValue({
        id: 'user-id',
        email: 'user@example.com',
        username: 'testuser',
        avatar_url: null,
      });

      const result = await service.validateToken('token');

      expect(supabaseService.client.auth.getUser).toHaveBeenCalledWith('token');
      expect(result).toEqual({
        id: 'user-id',
        email: 'user@example.com',
        username: 'testuser',
        avatar_url: null,
      });
    });

    it('should throw UnauthorizedException when Supabase returns error', async () => {
      supabaseService.client.auth.getUser.mockResolvedValue({
        data: { user: null },
        error: { message: 'invalid token' },
      });

      await expect(service.validateToken('token')).rejects.toBeInstanceOf(
        UnauthorizedException,
      );
    });
  });
});
