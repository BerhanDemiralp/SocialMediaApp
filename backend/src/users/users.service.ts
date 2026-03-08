import { Injectable, NotFoundException } from '@nestjs/common';
import { UsersRepository } from './repositories/users.repository';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Injectable()
export class UsersService {
  constructor(private usersRepository: UsersRepository) {}

  async getProfile(userId: string) {
    const user = await this.usersRepository.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    return {
      id: user.id,
      username: user.username,
      email: user.email,
      avatar_url: user.avatar_url,
      created_at: user.created_at,
      updated_at: user.updated_at,
    };
  }

  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto) {
    const user = await this.usersRepository.findById(userId);

    if (!user) {
      throw new NotFoundException('User not found');
    }

    if (
      updateProfileDto.username &&
      updateProfileDto.username !== user.username
    ) {
      const existingUser = await this.usersRepository.findByUsername(
        updateProfileDto.username,
      );
      if (existingUser) {
        throw new Error('Username already taken');
      }
    }

    const updatedUser = await this.usersRepository.update(userId, {
      username: updateProfileDto.username,
      avatar_url: updateProfileDto.avatar_url,
    });

    return {
      id: updatedUser.id,
      username: updatedUser.username,
      email: updatedUser.email,
      avatar_url: updatedUser.avatar_url,
      created_at: updatedUser.created_at,
      updated_at: updatedUser.updated_at,
    };
  }

  async searchUsers(query: string, limit: number, currentUserId: string) {
    const trimmed = query.trim();

    if (!trimmed) {
      throw new Error('Query is required');
    }

    const users = await this.usersRepository.searchByUsername(
      trimmed,
      limit || 20,
    );

    return users.filter((u) => u.id !== currentUserId);
  }
}
