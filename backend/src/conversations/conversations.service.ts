import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class ConversationsService {
  constructor(private readonly prisma: PrismaService) {}

  async listConversationsForUser(
    userId: string,
    limit?: number,
    cursor?: string,
  ) {
    const take = limit && limit > 0 ? limit : 20;

    const conversations = await this.prisma.conversations.findMany({
      where: {
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

    const items = conversations.map((conversation) => {
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
        participants,
        lastMessage: lastMessage
          ? {
              id: lastMessage.id,
              content: lastMessage.content,
              created_at: lastMessage.created_at,
            }
          : null,
      };
    });

    const nextCursor =
      conversations.length === take
        ? conversations[conversations.length - 1]?.id
        : null;

    return {
      items,
      nextCursor,
    };
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
}

