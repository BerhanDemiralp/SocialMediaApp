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

  async update(id: string, data: Prisma.usersUpdateInput) {
    return this.prismaService.users.update({
      where: { id },
      data,
    });
  }
}
