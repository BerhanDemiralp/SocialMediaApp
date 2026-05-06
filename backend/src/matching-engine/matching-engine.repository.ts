import { Injectable } from '@nestjs/common';
import {
  MomentMatchStatus,
  MomentMatchType,
  MomentOptInState,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

const momentMatchInclude = {
  user_a: {
    select: {
      id: true,
      username: true,
      avatar_url: true,
    },
  },
  user_b: {
    select: {
      id: true,
      username: true,
      avatar_url: true,
    },
  },
  group: {
    select: {
      id: true,
      name: true,
    },
  },
  conversation: {
    select: {
      id: true,
      type: true,
    },
  },
} satisfies Prisma.moment_matchesInclude;

export type MomentMatchWithRelations = Prisma.moment_matchesGetPayload<{
  include: typeof momentMatchInclude;
}>;

export interface CreateMomentMatchInput {
  matchType: MomentMatchType;
  userAId: string;
  userBId: string;
  conversationId: string;
  scheduledDay: Date;
  scheduledAt: Date;
  expiresAt: Date;
  groupId?: string | null;
}

@Injectable()
export class MatchingEngineRepository {
  constructor(private readonly prisma: PrismaService) {}

  async createMomentMatch(input: CreateMomentMatchInput) {
    return this.prisma.moment_matches.create({
      data: {
        match_type: input.matchType,
        user_a_id: input.userAId,
        user_b_id: input.userBId,
        group_id: input.groupId ?? null,
        conversation_id: input.conversationId,
        scheduled_day: input.scheduledDay,
        scheduled_at: input.scheduledAt,
        expires_at: input.expiresAt,
      },
      include: momentMatchInclude,
    });
  }

  async findActiveMatchesForUser(
    userId: string,
    matchType?: MomentMatchType,
    now = new Date(),
  ) {
    return this.prisma.moment_matches.findMany({
      where: {
        status: MomentMatchStatus.active,
        scheduled_at: { lte: now },
        expires_at: { gt: now },
        ...(matchType ? { match_type: matchType } : {}),
        OR: [{ user_a_id: userId }, { user_b_id: userId }],
      },
      orderBy: { scheduled_at: 'asc' },
      include: momentMatchInclude,
    });
  }

  async findActiveMatchForUserByTypeOnDay(
    userId: string,
    matchType: MomentMatchType,
    scheduledDay: Date,
  ) {
    return this.prisma.moment_matches.findFirst({
      where: {
        match_type: matchType,
        scheduled_day: scheduledDay,
        status: {
          in: [MomentMatchStatus.scheduled, MomentMatchStatus.active],
        },
        OR: [{ user_a_id: userId }, { user_b_id: userId }],
      },
      include: momentMatchInclude,
    });
  }

  async listHistoryForUser(userId: string, limit = 20, cursor?: string) {
    const take = limit > 0 ? limit : 20;

    return this.prisma.moment_matches.findMany({
      where: {
        OR: [{ user_a_id: userId }, { user_b_id: userId }],
      },
      orderBy: { scheduled_at: 'desc' },
      take,
      skip: cursor ? 1 : 0,
      ...(cursor ? { cursor: { id: cursor } } : {}),
      include: momentMatchInclude,
    });
  }

  async findExpiredActiveMatches(now: Date) {
    return this.prisma.moment_matches.findMany({
      where: {
        status: {
          in: [MomentMatchStatus.scheduled, MomentMatchStatus.active],
        },
        expires_at: { lte: now },
      },
      include: momentMatchInclude,
    });
  }

  async findDueScheduledMatches(now: Date) {
    return this.prisma.moment_matches.findMany({
      where: {
        status: MomentMatchStatus.scheduled,
        scheduled_at: { lte: now },
        expires_at: { gt: now },
      },
      include: momentMatchInclude,
    });
  }

  async findReminderCandidates(now: Date, inactiveSince: Date) {
    return this.prisma.moment_matches.findMany({
      where: {
        status: MomentMatchStatus.active,
        reminder_sent_at: null,
        scheduled_at: { lte: inactiveSince },
        expires_at: { gt: now },
      },
      include: momentMatchInclude,
    });
  }

  async getMessageStatsForMatch(match: {
    conversation_id: string;
    scheduled_at: Date;
    expires_at: Date;
  }) {
    const grouped = await this.prisma.messages.groupBy({
      by: ['sender_id'],
      where: {
        conversation_id: match.conversation_id,
        deleted_at: null,
        created_at: {
          gte: match.scheduled_at,
          lte: match.expires_at,
        },
      },
      _count: {
        _all: true,
      },
    });

    return {
      total: grouped.reduce((sum, item) => sum + item._count._all, 0),
      bySender: new Map(
        grouped.map((item) => [item.sender_id, item._count._all] as const),
      ),
    };
  }

  async findRecentFriendPairing(userAId: string, userBId: string, since: Date) {
    return this.prisma.moment_matches.findFirst({
      where: {
        match_type: MomentMatchType.friend,
        scheduled_at: { gte: since },
        OR: [
          { user_a_id: userAId, user_b_id: userBId },
          { user_a_id: userBId, user_b_id: userAId },
        ],
      },
      orderBy: { scheduled_at: 'desc' },
      include: momentMatchInclude,
    });
  }

  async updateStatus(matchId: string, status: MomentMatchStatus) {
    return this.prisma.moment_matches.update({
      where: { id: matchId },
      data: { status },
      include: momentMatchInclude,
    });
  }

  async markReminderSent(matchId: string, sentAt: Date) {
    return this.prisma.moment_matches.update({
      where: { id: matchId },
      data: { reminder_sent_at: sentAt },
      include: momentMatchInclude,
    });
  }

  async recordOptIn(matchId: string, userId: string) {
    const match = await this.prisma.moment_matches.findUnique({
      where: { id: matchId },
      select: { user_a_id: true, user_b_id: true },
    });

    if (!match) {
      return null;
    }

    const data =
      match.user_a_id === userId
        ? { user_a_opt_in: MomentOptInState.opted_in }
        : match.user_b_id === userId
          ? { user_b_opt_in: MomentOptInState.opted_in }
          : null;

    if (!data) {
      return null;
    }

    return this.prisma.moment_matches.update({
      where: { id: matchId },
      data,
      include: momentMatchInclude,
    });
  }

  async findByIdForParticipant(matchId: string, userId: string) {
    return this.prisma.moment_matches.findFirst({
      where: {
        id: matchId,
        OR: [{ user_a_id: userId }, { user_b_id: userId }],
      },
      include: momentMatchInclude,
    });
  }

  async listAcceptedFriendshipsForMatching() {
    return this.prisma.friendships.findMany({
      where: { status: 'accepted' },
      include: {
        requester: {
          select: { id: true, username: true, avatar_url: true },
        },
        addressee: {
          select: { id: true, username: true, avatar_url: true },
        },
      },
      orderBy: { created_at: 'asc' },
    });
  }

  async listGroupMembershipsForMatching() {
    return this.prisma.group_members.findMany({
      where: {
        group: {
          deleted_at: null,
        },
      },
      include: {
        user: {
          select: { id: true, username: true, avatar_url: true },
        },
        group: {
          select: { id: true, name: true },
        },
      },
      orderBy: { joined_at: 'asc' },
    });
  }

  async findAcceptedFriendshipBetween(userAId: string, userBId: string) {
    return this.prisma.friendships.findFirst({
      where: {
        status: 'accepted',
        OR: [
          { requester_id: userAId, addressee_id: userBId },
          { requester_id: userBId, addressee_id: userAId },
        ],
      },
    });
  }
}
