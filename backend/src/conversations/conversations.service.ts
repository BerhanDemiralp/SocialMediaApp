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

    const conversation = await this.prisma.conversations.findUnique({
      where: { id: conversationId },
      include: {
        participants: true,
        group: {
          include: {
            members: true,
          },
        },
      },
    });

    if (!conversation || conversation.deleted_at) {
      throw new NotFoundException('Conversation not found');
    }

    this.assertCanAccessConversation(conversation, userId);

    // For friend conversations, enforce that users are still friends
    // to keep chats read-only after a friendship is removed.
    if (conversation.type === ConversationType.friend) {
      const participantIds = conversation.participants
        .map((p) => p.user_id)
        .filter((id, index, arr) => !!id && arr.indexOf(id) === index);

      if (participantIds.length === 2) {
        const [userAId, userBId] = participantIds;

        const friendship = await this.prisma.friendships.findFirst({
          where: {
            status: 'accepted',
            OR: [
              { requester_id: userAId, addressee_id: userBId },
              { requester_id: userBId, addressee_id: userAId },
            ],
          },
        });

        if (!friendship) {
          throw new ForbiddenException(
            'Chat is read-only because you are no longer friends',
          );
        }
      }
    }

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
            where: { deleted_at: null },
            orderBy: { created_at: 'desc' },
            take: 1,
          },
          group: true,
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
        group: {
          include: {
            members: true,
          },
        },
      },
    });

    if (!conversation || conversation.deleted_at) {
      throw new NotFoundException('Conversation not found');
    }

    this.assertCanAccessConversation(conversation, userId);

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
    };
  }

  async assertUserCanAccessConversation(conversationId: string, userId: string) {
    const conversation = await this.prisma.conversations.findUnique({
      where: { id: conversationId },
      include: {
        participants: true,
        group: {
          include: {
            members: true,
          },
        },
      },
    });

    if (!conversation || conversation.deleted_at) {
      throw new NotFoundException('Conversation not found');
    }

    this.assertCanAccessConversation(conversation, userId);
  }

  private assertCanAccessConversation(
    conversation: {
      type: ConversationType;
      participants: { user_id: string }[];
      group?: {
        deleted_at: Date | null;
        members: { user_id: string }[];
      } | null;
    },
    userId: string,
  ) {
    if (conversation.type === ConversationType.group) {
      const isCurrentGroupMember =
        !!conversation.group &&
        !conversation.group.deleted_at &&
        conversation.group.members.some((member) => member.user_id === userId);

      if (!isCurrentGroupMember) {
        throw new ForbiddenException(
          'You are not allowed to access this group chat',
        );
      }

      return;
    }

    const isParticipant = conversation.participants.some(
      (p) => p.user_id === userId,
    );

    if (!isParticipant) {
      throw new ForbiddenException(
        'You are not allowed to access this conversation',
      );
    }
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
