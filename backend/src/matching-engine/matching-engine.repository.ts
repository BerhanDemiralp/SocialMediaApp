import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class MatchingEngineRepository {
  constructor(private readonly prisma: PrismaService) {}

  async findUsersWithoutActiveMatch(now: Date) {
    return this.prisma.users.findMany({
      where: {
        AND: [
          {
            matches_as_user_a: {
              none: {
                status: 'active',
                scheduled_at: { lte: now },
                expires_at: { gt: now },
              },
            },
          },
          {
            matches_as_user_b: {
              none: {
                status: 'active',
                scheduled_at: { lte: now },
                expires_at: { gt: now },
              },
            },
          },
        ],
      },
    });
  }

  async findAcceptedFriends(userId: string) {
    const friendships = await this.prisma.friendships.findMany({
      where: {
        status: 'accepted',
        OR: [{ requester_id: userId }, { addressee_id: userId }],
      },
    });

    return friendships.map((f) =>
      f.requester_id === userId ? f.addressee_id : f.requester_id,
    );
  }

  async findGroupMemberCandidates(userId: string) {
    const memberships = await this.prisma.group_members.findMany({
      where: { user_id: userId },
    });

    if (!memberships.length) {
      return [];
    }

    const groupIds = memberships.map((m) => m.group_id);

    const otherMembers = await this.prisma.group_members.findMany({
      where: {
        group_id: { in: groupIds },
        user_id: { not: userId },
      },
    });

    return otherMembers.map((m) => m.user_id);
  }

  async existsMatchBetweenUsersOnDay(
    userAId: string,
    userBId: string,
    dayStart: Date,
    dayEnd: Date,
  ) {
    const existing = await this.prisma.matches.findFirst({
      where: {
        scheduled_at: {
          gte: dayStart,
          lt: dayEnd,
        },
        OR: [
          { user_a_id: userAId, user_b_id: userBId },
          { user_a_id: userBId, user_b_id: userAId },
        ],
      },
    });

    return !!existing;
  }

  async createMatch(
    userAId: string,
    userBId: string,
    matchType: 'friends' | 'groups',
    scheduledAt: Date,
  ) {
    const expiresAt = new Date(scheduledAt.getTime() + 60 * 60 * 1000);

    return this.prisma.matches.create({
      data: {
        user_a_id: userAId,
        user_b_id: userBId,
        match_type: matchType,
        status: 'active',
        scheduled_at: scheduledAt,
        expires_at: expiresAt,
      },
    });
  }

  async findMatchesToEvaluate(now: Date) {
    return this.prisma.matches.findMany({
      where: {
        status: 'active',
        expires_at: { lte: now },
      },
    });
  }

  async getMessagesForMatchInWindow(
    matchId: string,
    start: Date,
    end: Date,
  ) {
    return this.prisma.messages.findMany({
      where: {
        match_id: matchId,
        created_at: {
          gte: start,
          lt: end,
        },
      },
    });
  }

  async updateMatchStatus(matchId: string, status: string) {
    return this.prisma.matches.update({
      where: { id: matchId },
      data: { status },
    });
  }

  async getCurrentActiveMatchForUser(userId: string, now: Date) {
    return this.prisma.matches.findFirst({
      where: {
        status: 'active',
        scheduled_at: { lte: now },
        expires_at: { gt: now },
        OR: [{ user_a_id: userId }, { user_b_id: userId }],
      },
      orderBy: { scheduled_at: 'desc' },
    });
  }

  async getHistoricalMatchesForUser(
    userId: string,
    skip: number,
    take: number,
  ) {
    return this.prisma.matches.findMany({
      where: {
        status: { not: 'active' },
        OR: [{ user_a_id: userId }, { user_b_id: userId }],
      },
      orderBy: { scheduled_at: 'desc' },
      skip,
      take,
    });
  }

  async setGroupOptIn(matchId: string, userId: string) {
    const match = await this.prisma.matches.findUnique({
      where: { id: matchId },
    });

    if (!match) {
      return null;
    }

    if (match.user_a_id === userId) {
      return this.prisma.matches.update({
        where: { id: matchId },
        data: { user_a_opt_in: true },
      });
    }

    if (match.user_b_id === userId) {
      return this.prisma.matches.update({
        where: { id: matchId },
        data: { user_b_opt_in: true },
      });
    }

    return null;
  }
}

