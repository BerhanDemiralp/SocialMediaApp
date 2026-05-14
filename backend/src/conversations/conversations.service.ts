import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import {
  ConversationMode,
  ConversationType,
  MomentMatchStatus,
  MomentMatchType,
  MomentOptInState,
  Prisma,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ConversationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listConversationsForUser(
    userId: string,
    limit?: number,
    cursor?: string,
    type?: ConversationType,
  ) {
    const take = limit && limit > 0 ? limit : 20;

    const conversations = await this.prisma.conversations.findMany({
      where: {
        deleted_at: null,
        ...(type && { type }),
        participants: {
          some: { user_id: userId },
        },
      },
      orderBy: {
        updated_at: 'desc',
      },
      take,
      skip: cursor ? 1 : 0,
      ...(cursor && { cursor: { id: cursor } }),
      include: {
        participants: {
          include: {
            user: true,
          },
        },
        messages: {
          where: { deleted_at: null },
          orderBy: { created_at: 'desc' },
          take: 1,
        },
        group: true,
        moment_matches: {
          orderBy: { scheduled_at: 'desc' },
          take: 1,
        },
        write_exceptions: {
          where: { expires_at: { gt: new Date() } },
          orderBy: { expires_at: 'desc' },
          take: 1,
        },
      },
    });

    const items = conversations.map((conversation) =>
      this.mapConversationToSummary(conversation),
    );

    const nextCursor =
      conversations.length === take
        ? conversations[conversations.length - 1]?.id
        : null;

    return {
      items,
      nextCursor,
    };
  }

  async createMessageForConversation(
    conversationId: string,
    userId: string,
    content: string,
  ) {
    if (!content.trim()) {
      throw new BadRequestException('Message content cannot be empty');
    }

    const conversation = await this.getAuthorizedConversation(
      conversationId,
      userId,
    );

    await this.assertConversationWritable(conversation.id);

    const message = await this.prisma.$transaction(async (tx) => {
      const created = await tx.messages.create({
        data: {
          conversation_id: conversation.id,
          sender_id: userId,
          content: content.trim(),
        },
        include: {
          sender: true,
        },
      });

      await tx.conversations.update({
        where: { id: conversation.id },
        data: { updated_at: new Date() },
      });

      return created;
    });

    return message;
  }

  async ensureFriendConversationBetweenUsers(userId: string, friendId: string) {
    if (userId === friendId) {
      throw new BadRequestException(
        'You cannot create a conversation with yourself',
      );
    }

    const friendship = await this.prisma.friendships.findFirst({
      where: {
        status: 'accepted',
        OR: [
          { requester_id: userId, addressee_id: friendId },
          { requester_id: friendId, addressee_id: userId },
        ],
      },
    });

    if (!friendship) {
      throw new ForbiddenException('Users are not friends');
    }

    const conversation = await this.ensureDirectConversationBetweenUsers(
      userId,
      friendId,
      ConversationType.friend,
      ConversationMode.friend,
    );

    const conversationWithRelations =
      await this.prisma.conversations.findUnique({
        where: { id: conversation.id },
        include: {
          participants: {
            include: {
              user: true,
            },
          },
          messages: {
            where: { deleted_at: null },
            orderBy: { created_at: 'desc' },
            take: 1,
          },
          group: true,
          moment_matches: {
            orderBy: { scheduled_at: 'desc' },
            take: 1,
          },
          write_exceptions: {
            where: { expires_at: { gt: new Date() } },
            orderBy: { expires_at: 'desc' },
            take: 1,
          },
        },
      });

    if (!conversationWithRelations) {
      throw new NotFoundException('Conversation not found after creation');
    }

    return this.mapConversationToSummary(conversationWithRelations);
  }

  async createGroupPairConversationForMoment(userAId: string, userBId: string) {
    if (userAId === userBId) {
      throw new BadRequestException(
        'You cannot create a group pair conversation with yourself',
      );
    }

    const conversation = await this.ensureDirectConversationBetweenUsers(
      userAId,
      userBId,
      ConversationType.group_pair,
      ConversationMode.read_only,
    );

    const conversationWithRelations =
      await this.prisma.conversations.findUnique({
        where: { id: conversation.id },
        include: {
          participants: {
            include: {
              user: true,
            },
          },
          messages: {
            where: { deleted_at: null },
            orderBy: { created_at: 'desc' },
            take: 1,
          },
          group: true,
          moment_matches: {
            orderBy: { scheduled_at: 'desc' },
            take: 1,
          },
          write_exceptions: {
            where: { expires_at: { gt: new Date() } },
            orderBy: { expires_at: 'desc' },
            take: 1,
          },
        },
      });

    if (!conversationWithRelations) {
      throw new NotFoundException('Conversation not found after creation');
    }

    return this.mapConversationToSummary(conversationWithRelations);
  }

  async markDirectConversationReadOnlyAfterUnfriend(
    userAId: string,
    userBId: string,
  ) {
    const conversation = await this.findDirectConversationBetweenUsers(
      userAId,
      userBId,
    );

    if (!conversation) {
      return null;
    }

    const hasGroupMoment = await this.prisma.moment_matches.findFirst({
      where: {
        conversation_id: conversation.id,
        match_type: MomentMatchType.group,
      },
      select: { id: true },
    });

    return this.prisma.conversations.update({
      where: { id: conversation.id },
      data: {
        type: hasGroupMoment
          ? ConversationType.group_pair
          : ConversationType.friend,
        mode: ConversationMode.read_only,
      },
    });
  }

  async grantOneHourWriteException(
    conversationId: string,
    userId: string,
    grantedToId?: string,
    now = new Date(),
  ) {
    await this.getAuthorizedConversation(conversationId, userId);
    const expiresAt = new Date(now.getTime() + 60 * 60 * 1000);

    await this.prisma.conversation_write_exceptions.create({
      data: {
        conversation_id: conversationId,
        granted_by_id: userId,
        granted_to_id: grantedToId ?? null,
        expires_at: expiresAt,
      },
    });

    await this.prisma.conversations.update({
      where: { id: conversationId },
      data: { mode: ConversationMode.exception },
    });

    return { expires_at: expiresAt };
  }

  async getConversationMessages(
    conversationId: string,
    userId: string,
    limit?: number,
    cursor?: string,
  ) {
    await this.getAuthorizedConversation(conversationId, userId);
    const momentState = await this.getMomentConversationState(conversationId);

    const take = limit && limit > 0 ? limit : 50;

    const messages = await this.prisma.messages.findMany({
      where: { conversation_id: conversationId, deleted_at: null },
      include: {
        sender: true,
      },
      orderBy: { created_at: 'desc' },
      take,
      skip: cursor ? 1 : 0,
      ...(cursor && { cursor: { id: cursor } }),
    });

    const nextCursor =
      messages.length === take ? messages[messages.length - 1]?.id : null;

    return {
      items: messages,
      nextCursor,
      writable: momentState.writable,
    };
  }

  async assertUserCanAccessConversation(
    conversationId: string,
    userId: string,
  ) {
    await this.getAuthorizedConversation(conversationId, userId);
  }

  private async getAuthorizedConversation(
    conversationId: string,
    userId: string,
  ) {
    const conversation = await this.prisma.conversations.findUnique({
      where: { id: conversationId },
      select: {
        id: true,
        type: true,
        deleted_at: true,
        group: {
          select: {
            id: true,
            deleted_at: true,
          },
        },
      },
    });

    if (!conversation || conversation.deleted_at) {
      throw new NotFoundException('Conversation not found');
    }

    if (conversation.type === ConversationType.group) {
      if (!conversation.group || conversation.group.deleted_at) {
        throw new ForbiddenException(
          'You are not allowed to access this group chat',
        );
      }

      const membership = await this.prisma.group_members.findUnique({
        where: {
          user_id_group_id: {
            user_id: userId,
            group_id: conversation.group.id,
          },
        },
        select: { id: true },
      });

      if (!membership) {
        throw new ForbiddenException(
          'You are not allowed to access this group chat',
        );
      }

      return conversation;
    }

    const participant = await this.prisma.conversation_participants.findUnique({
      where: {
        conversation_id_user_id: {
          conversation_id: conversation.id,
          user_id: userId,
        },
      },
      select: { id: true },
    });

    if (!participant) {
      throw new ForbiddenException(
        'You are not allowed to access this conversation',
      );
    }

    return conversation;
  }

  private async assertConversationWritable(conversationId: string) {
    const momentState = await this.getMomentConversationState(conversationId);

    if (!momentState.writable) {
      throw new ForbiddenException('This conversation is read-only');
    }
  }

  private async getMomentConversationState(conversationId: string) {
    const conversation = await this.prisma.conversations.findUnique({
      where: { id: conversationId },
      select: {
        id: true,
        type: true,
        direct_user_low_id: true,
        direct_user_high_id: true,
      },
    });

    if (!conversation) {
      return { writable: false };
    }

    if (conversation.type === ConversationType.group) {
      return { writable: true };
    }

    const directUserIds = await this.getDirectConversationUserIds(conversation);

    if (directUserIds.length === 2) {
      const [userAId, userBId] = directUserIds;
      const friendship = await this.prisma.friendships.findFirst({
        where: {
          status: 'accepted',
          OR: [
            { requester_id: userAId, addressee_id: userBId },
            { requester_id: userBId, addressee_id: userAId },
          ],
        },
        select: { id: true },
      });

      if (friendship) {
        return { writable: true, mode: ConversationMode.friend };
      }
    }

    const exception = await this.prisma.conversation_write_exceptions.findFirst(
      {
        where: {
          conversation_id: conversationId,
          expires_at: { gt: new Date() },
        },
        orderBy: { expires_at: 'desc' },
        select: { id: true },
      },
    );

    if (exception) {
      return { writable: true, mode: ConversationMode.exception };
    }

    const match = await this.prisma.moment_matches.findFirst({
      where: { conversation_id: conversationId },
      orderBy: { scheduled_at: 'desc' },
    });

    if (!match) {
      return { writable: false, mode: ConversationMode.read_only };
    }

    if (match.match_type === MomentMatchType.friend) {
      const isWithinMomentWindow = this.isWithinMomentWindow(match, new Date());

      return {
        writable: isWithinMomentWindow || directUserIds.length !== 2,
        mode: ConversationMode.friend,
      };
    }

    const hasMutualOptIn =
      match.user_a_opt_in === MomentOptInState.opted_in &&
      match.user_b_opt_in === MomentOptInState.opted_in;
    const isActiveMoment =
      match.status === MomentMatchStatus.active ||
      this.isWithinMomentWindow(match, new Date());

    return {
      writable: isActiveMoment || hasMutualOptIn,
      mode:
        isActiveMoment || hasMutualOptIn
          ? ConversationMode.active_moment
          : ConversationMode.read_only,
    };
  }

  private isWithinMomentWindow(
    match: { scheduled_at?: Date; expires_at?: Date },
    now: Date,
  ) {
    if (!match.scheduled_at || !match.expires_at) {
      return false;
    }

    return (
      match.scheduled_at.getTime() <= now.getTime() &&
      match.expires_at.getTime() > now.getTime()
    );
  }

  private getDirectPairIds(userAId: string, userBId: string) {
    return userAId < userBId
      ? { lowId: userAId, highId: userBId }
      : { lowId: userBId, highId: userAId };
  }

  private async findDirectConversationBetweenUsers(
    userAId: string,
    userBId: string,
  ) {
    const { lowId, highId } = this.getDirectPairIds(userAId, userBId);

    const canonical = await this.prisma.conversations.findFirst({
      where: {
        deleted_at: null,
        direct_user_low_id: lowId,
        direct_user_high_id: highId,
      },
    });

    if (canonical) {
      return canonical;
    }

    return this.prisma.conversations.findFirst({
      where: {
        deleted_at: null,
        type: { in: [ConversationType.friend, ConversationType.group_pair] },
        participants: {
          some: { user_id: userAId },
        },
        AND: {
          participants: {
            some: { user_id: userBId },
          },
        },
      },
      orderBy: [{ type: 'asc' }, { created_at: 'asc' }],
    });
  }

  private async ensureDirectConversationBetweenUsers(
    userAId: string,
    userBId: string,
    type: ConversationType,
    mode: ConversationMode,
  ) {
    const { lowId, highId } = this.getDirectPairIds(userAId, userBId);
    const existing = await this.findDirectConversationBetweenUsers(
      userAId,
      userBId,
    );

    if (existing) {
      return this.prisma.conversations.update({
        where: { id: existing.id },
        data: {
          direct_user_low_id: lowId,
          direct_user_high_id: highId,
          type:
            type === ConversationType.friend ||
            existing.type === ConversationType.friend
              ? ConversationType.friend
              : ConversationType.group_pair,
          mode:
            type === ConversationType.friend ||
            existing.mode === ConversationMode.friend
              ? ConversationMode.friend
              : (existing.mode ?? mode),
        },
      });
    }

    const participantIds = [userAId, userBId].filter(
      (id, index, arr) => !!id && arr.indexOf(id) === index,
    );

    const participantsCreate = participantIds.map((participantId) => ({
      user: { connect: { id: participantId } },
    }));

    try {
      return await this.prisma.conversations.create({
        data: {
          type,
          mode,
          title: null,
          direct_user_low_id: lowId,
          direct_user_high_id: highId,
          participants: {
            create: participantsCreate,
          },
        },
      });
    } catch (error) {
      if (
        error instanceof Prisma.PrismaClientKnownRequestError &&
        error.code === 'P2002'
      ) {
        const racedConversation = await this.findDirectConversationBetweenUsers(
          userAId,
          userBId,
        );

        if (racedConversation) {
          return racedConversation;
        }
      }

      throw error;
    }
  }

  private async getDirectConversationUserIds(conversation: {
    id: string;
    direct_user_low_id?: string | null;
    direct_user_high_id?: string | null;
  }) {
    if (conversation.direct_user_low_id && conversation.direct_user_high_id) {
      return [
        conversation.direct_user_low_id,
        conversation.direct_user_high_id,
      ];
    }

    const participants = await this.prisma.conversation_participants.findMany({
      where: { conversation_id: conversation.id },
      select: { user_id: true },
    });

    return participants
      .map((p) => p.user_id)
      .filter((id, index, arr) => !!id && arr.indexOf(id) === index);
  }

  private mapConversationToSummary(conversation: {
    id: string;
    type: ConversationType;
    title: string | null;
    participants: {
      user: { id: string; username: string; avatar_url: string | null };
    }[];
    messages: { id: string; content: string; created_at: Date }[];
    group?: { id: string; name: string } | null;
    mode?: ConversationMode | null;
    write_exceptions?: { id: string; expires_at: Date }[];
    moment_matches?: {
      match_type: MomentMatchType;
      status: MomentMatchStatus;
      scheduled_at: Date;
      expires_at: Date;
      user_a_opt_in: MomentOptInState;
      user_b_opt_in: MomentOptInState;
    }[];
  }) {
    const lastMessage = conversation.messages[0] ?? null;

    const participants = conversation.participants.map((p) => ({
      id: p.user.id,
      username: p.user.username,
      avatar_url: p.user.avatar_url,
    }));

    return {
      id: conversation.id,
      type: conversation.type,
      title: conversation.group?.name ?? conversation.title,
      friendMatchId: null,
      groupId: conversation.group?.id ?? null,
      groupName: conversation.group?.name ?? null,
      writable: this.isConversationSummaryWritable(conversation),
      participants,
      lastMessage: lastMessage
        ? {
            id: lastMessage.id,
            content: lastMessage.content,
            created_at: lastMessage.created_at,
          }
        : null,
    };
  }

  private isConversationSummaryWritable(conversation: {
    type?: ConversationType;
    mode?: ConversationMode | null;
    write_exceptions?: { id: string; expires_at: Date }[];
    moment_matches?: {
      match_type: MomentMatchType;
      status: MomentMatchStatus;
      scheduled_at: Date;
      expires_at: Date;
      user_a_opt_in: MomentOptInState;
      user_b_opt_in: MomentOptInState;
    }[];
  }) {
    if (conversation.type === ConversationType.group) {
      return true;
    }

    if (conversation.mode === ConversationMode.friend) {
      return true;
    }

    if (conversation.write_exceptions?.length) {
      return true;
    }

    const match = conversation.moment_matches?.[0];

    if (!match) {
      return conversation.mode !== ConversationMode.read_only;
    }

    if (match.match_type === MomentMatchType.friend) {
      return true;
    }

    return (
      match.status === MomentMatchStatus.active ||
      this.isWithinMomentWindow(match, new Date()) ||
      (match.user_a_opt_in === MomentOptInState.opted_in &&
        match.user_b_opt_in === MomentOptInState.opted_in)
    );
  }
}
