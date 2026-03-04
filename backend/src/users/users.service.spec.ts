import { Test, TestingModule } from '@nestjs/testing';
import { UsersService } from './users.service';
import { UsersRepository } from './repositories/users.repository';
import { NotFoundException } from '@nestjs/common';

describe('UsersService', () => {
  let service: UsersService;
  let usersRepository: {
    findById: jest.Mock;
    findByUsername: jest.Mock;
    update: jest.Mock;
  };

  beforeEach(async () => {
    usersRepository = {
      findById: jest.fn(),
      findByUsername: jest.fn(),
      update: jest.fn(),
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        UsersService,
        {
          provide: UsersRepository,
          useValue: usersRepository,
        },
      ],
    }).compile();

    service = module.get<UsersService>(UsersService);
  });

  describe('getProfile', () => {
    it('should return user profile when user exists', async () => {
      const user = {
        id: 'user-id',
        username: 'testuser',
        email: 'user@example.com',
        avatar_url: 'avatar.png',
        created_at: new Date('2024-01-01T00:00:00Z'),
        updated_at: new Date('2024-01-02T00:00:00Z'),
      };

      usersRepository.findById.mockResolvedValue(user);

      const result = await service.getProfile('user-id');

      expect(usersRepository.findById).toHaveBeenCalledWith('user-id');
      expect(result).toEqual({
        id: user.id,
        username: user.username,
        email: user.email,
        avatar_url: user.avatar_url,
        created_at: user.created_at,
        updated_at: user.updated_at,
      });
    });

    it('should throw NotFoundException when user does not exist', async () => {
      usersRepository.findById.mockResolvedValue(null);

      await expect(service.getProfile('missing-id')).rejects.toBeInstanceOf(
        NotFoundException,
      );
    });
  });

  describe('updateProfile', () => {
    it('should update avatar and return updated profile when username unchanged', async () => {
      const existingUser = {
        id: 'user-id',
        username: 'testuser',
        email: 'user@example.com',
        avatar_url: 'old.png',
        created_at: new Date('2024-01-01T00:00:00Z'),
        updated_at: new Date('2024-01-02T00:00:00Z'),
      };

      const updatedUser = {
        ...existingUser,
        avatar_url: 'new.png',
        updated_at: new Date('2024-01-03T00:00:00Z'),
      };

      usersRepository.findById.mockResolvedValue(existingUser);
      usersRepository.update.mockResolvedValue(updatedUser);

      const result = await service.updateProfile('user-id', {
        avatar_url: 'new.png',
      } as any);

      expect(usersRepository.findById).toHaveBeenCalledWith('user-id');
      expect(usersRepository.update).toHaveBeenCalledWith('user-id', {
        username: undefined,
        avatar_url: 'new.png',
      });
      expect(result).toEqual({
        id: updatedUser.id,
        username: updatedUser.username,
        email: updatedUser.email,
        avatar_url: updatedUser.avatar_url,
        created_at: updatedUser.created_at,
        updated_at: updatedUser.updated_at,
      });
    });

    it('should validate username uniqueness when username changes', async () => {
      const existingUser = {
        id: 'user-id',
        username: 'olduser',
        email: 'user@example.com',
        avatar_url: 'avatar.png',
        created_at: new Date('2024-01-01T00:00:00Z'),
        updated_at: new Date('2024-01-02T00:00:00Z'),
      };

      const updatedUser = {
        ...existingUser,
        username: 'newuser',
        updated_at: new Date('2024-01-03T00:00:00Z'),
      };

      usersRepository.findById.mockResolvedValue(existingUser);
      usersRepository.findByUsername.mockResolvedValueOnce(null);
      usersRepository.update.mockResolvedValue(updatedUser);

      const result = await service.updateProfile('user-id', {
        username: 'newuser',
      } as any);

      expect(usersRepository.findByUsername).toHaveBeenCalledWith('newuser');
      expect(usersRepository.update).toHaveBeenCalledWith('user-id', {
        username: 'newuser',
        avatar_url: undefined,
      });
      expect(result.username).toBe('newuser');
    });

    it('should throw error when username is already taken', async () => {
      const existingUser = {
        id: 'user-id',
        username: 'olduser',
        email: 'user@example.com',
        avatar_url: 'avatar.png',
        created_at: new Date('2024-01-01T00:00:00Z'),
        updated_at: new Date('2024-01-02T00:00:00Z'),
      };

      const anotherUser = { id: 'another-id', username: 'newuser' };

      usersRepository.findById.mockResolvedValue(existingUser);
      usersRepository.findByUsername.mockResolvedValueOnce(anotherUser);

      await expect(
        service.updateProfile('user-id', { username: 'newuser' } as any),
      ).rejects.toThrow('Username already taken');
    });

    it('should throw NotFoundException when user does not exist', async () => {
      usersRepository.findById.mockResolvedValue(null);

      await expect(
        service.updateProfile('missing-id', { username: 'test' } as any),
      ).rejects.toBeInstanceOf(NotFoundException);
    });
  });
});
