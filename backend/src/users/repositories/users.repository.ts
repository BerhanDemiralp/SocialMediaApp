import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { Prisma } from '@prisma/client';

@Injectable()
export class UsersRepository {
  constructor(private prismaService: PrismaService) {}

  async findById(id: string) {
    return this.prismaService.users.findUnique({
      where: { id },
    });
  }

  async findByEmail(email: string) {
    return this.prismaService.users.findUnique({
      where: { email },
    });
  }

  async findByUsername(username: string) {
    return this.prismaService.users.findUnique({
      where: { username },
    });
  }

  async searchByUsername(query: string, limit: number) {
    const normalizedLimit = limit > 0 && limit <= 50 ? limit : 20;
    const q = query.trim();

    if (!q) {
      return [];
    }

    return this.prismaService.users.findMany({
      where: {
        username: {
          contains: q,
          mode: 'insensitive',
        },
      },
      take: normalizedLimit,
      orderBy: {
        username: 'asc',
      },
      select: {
        id: true,
        username: true,
        avatar_url: true,
      },
    });
  }

  async update(id: string, data: Prisma.usersUpdateInput) {
    return this.prismaService.users.update({
      where: { id },
      data,
    });
  }
}
