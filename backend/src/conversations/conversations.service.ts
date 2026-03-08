import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { ConversationType } from '@prisma/client';
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
          orderBy: { created_at: 'desc' },
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

  async ensureFriendConversationBetweenUsers(
    userId: string,
    friendId: string,
  ) {
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

    let conversation = await this.prisma.conversations.findFirst({
      where: {
        type: ConversationType.friend,
        participants: {
          some: { user_id: userId },
        },
        AND: {
          participants: {
            some: { user_id: friendId },
          },
        },
      },
    });

    if (!conversation) {
      const participantIds = [userId, friendId].filter(
        (id, index, arr) => !!id && arr.indexOf(id) === index,
      );

      const participantsCreate = participantIds.map((participantId) => ({
        user: { connect: { id: participantId } },
      }));

      conversation = await this.prisma.conversations.create({
        data: {
          type: ConversationType.friend,
          title: null,
          friend_match_id: null,
          group_match_id: null,
          participants: {
            create: participantsCreate,
          },
        },
      });
    }

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
            orderBy: { created_at: 'desc' },
            take: 1,
          },
        },
      });

    if (!conversationWithRelations) {
      throw new NotFoundException('Conversation not found after creation');
    }

    return this.mapConversationToSummary(conversationWithRelations);
  }

  async getConversationMessages(
    conversationId: string,
    userId: string,
    limit?: number,
    cursor?: string,
  ) {
    const conversation = await this.prisma.conversations.findUnique({
      where: { id: conversationId },
      include: {
        participants: true,
      },
    });

    if (!conversation) {
      throw new NotFoundException('Conversation not found');
    }

    const isParticipant = conversation.participants.some(
      (p) => p.user_id === userId,
    );

    if (!isParticipant) {
      throw new ForbiddenException(
        'You are not allowed to view messages for this conversation',
      );
    }

    const take = limit && limit > 0 ? limit : 50;

    const messages = await this.prisma.messages.findMany({
      where: { conversation_id: conversationId },
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
    };
  }

  private mapConversationToSummary(conversation: {
    id: string;
    type: ConversationType;
    title: string | null;
    friend_match_id: string | null;
    participants: {
      user: { id: string; username: string; avatar_url: string | null };
    }[];
    messages: { id: string; content: string; created_at: Date }[];
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
      title: conversation.title,
      friendMatchId: conversation.friend_match_id,
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
}
