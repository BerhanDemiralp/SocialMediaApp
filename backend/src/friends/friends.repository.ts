import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class FriendsRepository {
  constructor(private prisma: PrismaService) {}

  async findFriendshipById(id: string) {
    return this.prisma.friendships.findUnique({
      where: { id },
    });
  }

  async findFriendshipBetweenUsers(userAId: string, userBId: string) {
    return this.prisma.friendships.findFirst({
      where: {
        OR: [
          { requester_id: userAId, addressee_id: userBId },
          { requester_id: userBId, addressee_id: userAId },
        ],
      },
    });
  }

  async createFriendRequest(requesterId: string, addresseeId: string) {
    return this.prisma.friendships.create({
      data: {
        requester_id: requesterId,
        addressee_id: addresseeId,
        status: 'pending',
      },
    });
  }

  async updateFriendshipStatus(id: string, status: string) {
    return this.prisma.friendships.update({
      where: { id },
      data: { status },
    });
  }

  async listAcceptedFriendshipsForUser(userId: string) {
    return this.prisma.friendships.findMany({
      where: {
        status: 'accepted',
        OR: [{ requester_id: userId }, { addressee_id: userId }],
      },
      include: {
        requester: true,
        addressee: true,
      },
    });
  }

  async listIncomingRequests(userId: string) {
    return this.prisma.friendships.findMany({
      where: {
        status: 'pending',
        addressee_id: userId,
      },
      include: {
        requester: true,
      },
    });
  }

  async listOutgoingRequests(userId: string) {
    return this.prisma.friendships.findMany({
      where: {
        status: 'pending',
        requester_id: userId,
      },
      include: {
        addressee: true,
      },
    });
  }
}

