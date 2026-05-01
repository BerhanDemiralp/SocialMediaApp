import { Test, TestingModule } from '@nestjs/testing';
import { ConversationsService } from './conversations.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  BadRequestException,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { ConversationType } from '@prisma/client';

describe('ConversationsService', () => {
  let service: ConversationsService;
  let prisma: {
    $transaction: jest.Mock;
    conversations: {
      findMany: jest.Mock;
      findUnique: jest.Mock;
      findFirst: jest.Mock;
      create: jest.Mock;
      update: jest.Mock;
    };
    messages: { findMany: jest.Mock; create: jest.Mock };
    friendships: { findFirst: jest.Mock };
    matches: { create: jest.Mock };
  };

  beforeEach(async () => {
    prisma = {
      $transaction: jest.fn(async (callback) =>
        callback({
          messages: prisma.messages,
          conversations: prisma.conversations,
        }),
      ),
      conversations: {
        findMany: jest.fn(),
        findUnique: jest.fn(),
        findFirst: jest.fn(),
        create: jest.fn(),
        update: jest.fn(),
      },
      messages: {
        findMany: jest.fn(),
        create: jest.fn(),
      },
      friendships: {
        findFirst: jest.fn(),
      },
      matches: {
        create: jest.fn(),
      },
    };

    const module: TestingModule = await Test.createTestingModule({
      providers: [
        ConversationsService,
        {
          provide: PrismaService,
          useValue: prisma,
        },
      ],
    }).compile();

    service = module.get(ConversationsService);
  });

  it('lists conversations with participant summaries and last message', async () => {
    const now = new Date();
    prisma.conversations.findMany.mockResolvedValue([
      {
        id: 'conv-1',
        type: 'friend',
        title: null,
        updated_at: now,
        group: null,
        participants: [
          {
            user_id: 'user-1',
            user: { id: 'user-1', username: 'u1', avatar_url: null },
          },
          {
            user_id: 'user-2',
            user: { id: 'user-2', username: 'u2', avatar_url: 'a2' },
          },
        ],
        messages: [
          {
            id: 'msg-1',
            content: 'hello',
            created_at: now,
          },
        ],
      },
    ]);

    const result = await service.listConversationsForUser('user-1', 10);

    expect(prisma.conversations.findMany).toHaveBeenCalled();
    expect(result.items).toHaveLength(1);
    expect(result.items[0]).toEqual({
      id: 'conv-1',
      type: 'friend',
      title: null,
      friendMatchId: null,
      groupId: null,
      groupName: null,
      participants: [
        { id: 'user-1', username: 'u1', avatar_url: null },
        { id: 'user-2', username: 'u2', avatar_url: 'a2' },
      ],
      lastMessage: {
        id: 'msg-1',
        content: 'hello',
        created_at: now,
      },
    });
    expect(result.nextCursor).toBeNull();
  });

  it('filters conversations by type when provided', async () => {
    prisma.conversations.findMany.mockResolvedValue([]);

    await service.listConversationsForUser(
      'user-1',
      10,
      undefined,
      ConversationType.friend,
    );

    expect(prisma.conversations.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ type: ConversationType.friend }),
      }),
    );
  });

  it('throws NotFound when conversation is missing', async () => {
    prisma.conversations.findUnique.mockResolvedValue(null);

    await expect(
      service.getConversationMessages('conv-missing', 'user-1', 10),
    ).rejects.toBeInstanceOf(NotFoundException);
  });

  it('throws Forbidden when user is not a participant', async () => {
    prisma.conversations.findUnique.mockResolvedValue({
      id: 'conv-1',
      type: ConversationType.friend,
      deleted_at: null,
      participants: [{ user_id: 'other-user' }],
      group: null,
    });

    await expect(
      service.getConversationMessages('conv-1', 'user-1', 10),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.messages.findMany).not.toHaveBeenCalled();
  });

  it('returns paginated messages for participant', async () => {
    const now = new Date();
    prisma.conversations.findUnique.mockResolvedValue({
      id: 'conv-1',
      type: ConversationType.friend,
      deleted_at: null,
      participants: [{ user_id: 'user-1' }],
      group: null,
    });
    prisma.messages.findMany.mockResolvedValue([
      {
        id: 'msg-1',
        conversation_id: 'conv-1',
        content: 'hello',
        created_at: now,
      },
    ]);

    const result = await service.getConversationMessages(
      'conv-1',
      'user-1',
      10,
    );

    expect(prisma.messages.findMany).toHaveBeenCalled();
    expect(result.items).toHaveLength(1);
    expect(result.nextCursor).toBeNull();
  });

  it('creates a new friend conversation when none exists', async () => {
    prisma.friendships.findFirst.mockResolvedValue({
      id: 'friendship-1',
      requester_id: 'user-1',
      addressee_id: 'user-2',
      status: 'accepted',
    });

    prisma.conversations.findFirst.mockResolvedValueOnce(null);

    prisma.conversations.create.mockResolvedValue({
      id: 'conv-1',
      friend_match_id: null,
    });

    prisma.matches.create.mockResolvedValue({
      id: 'match-1',
    });

    prisma.conversations.update.mockResolvedValue({
      id: 'conv-1',
      friend_match_id: 'match-1',
    });

    prisma.conversations.findUnique.mockResolvedValue({
      id: 'conv-1',
      type: ConversationType.friend,
      title: null,
      group: null,
      participants: [
        {
          user: { id: 'user-1', username: 'u1', avatar_url: null },
        },
        {
          user: { id: 'user-2', username: 'u2', avatar_url: 'a2' },
        },
      ],
      messages: [],
    });

    const result =
      await service.ensureFriendConversationBetweenUsers('user-1', 'user-2');

    expect(prisma.conversations.create).toHaveBeenCalled();
    expect(result).toEqual({
      id: 'conv-1',
      type: ConversationType.friend,
      title: null,
      friendMatchId: null,
      groupId: null,
      groupName: null,
      participants: [
        { id: 'user-1', username: 'u1', avatar_url: null },
        { id: 'user-2', username: 'u2', avatar_url: 'a2' },
      ],
      lastMessage: null,
    });
  });

  it('reuses existing friend conversation when present', async () => {
    prisma.friendships.findFirst.mockResolvedValue({
      id: 'friendship-1',
      requester_id: 'user-1',
      addressee_id: 'user-2',
      status: 'accepted',
    });

    prisma.conversations.findFirst.mockResolvedValueOnce({
      id: 'conv-1',
    });

    prisma.conversations.findUnique.mockResolvedValue({
      id: 'conv-1',
      type: ConversationType.friend,
      title: null,
      group: null,
      participants: [
        {
          user: { id: 'user-1', username: 'u1', avatar_url: null },
        },
        {
          user: { id: 'user-2', username: 'u2', avatar_url: 'a2' },
        },
      ],
      messages: [],
    });

    const result =
      await service.ensureFriendConversationBetweenUsers('user-1', 'user-2');

    expect(prisma.conversations.create).not.toHaveBeenCalled();
    expect(result.id).toBe('conv-1');
  });

  it('throws when users are not friends', async () => {
    prisma.friendships.findFirst.mockResolvedValue(null);

    await expect(
      service.ensureFriendConversationBetweenUsers('user-1', 'user-2'),
    ).rejects.toBeInstanceOf(ForbiddenException);
  });

  it('prevents creating a conversation with self', async () => {
    await expect(
      service.ensureFriendConversationBetweenUsers('user-1', 'user-1'),
    ).rejects.toBeInstanceOf(BadRequestException);
  });

  it('maps group conversations with group metadata', async () => {
    const now = new Date();
    prisma.conversations.findMany.mockResolvedValue([
      {
        id: 'group-conv-1',
        type: ConversationType.group,
        title: 'Fallback title',
        group: { id: 'group-1', name: 'Book Club' },
        participants: [
          {
            user: { id: 'user-1', username: 'u1', avatar_url: null },
          },
        ],
        messages: [
          {
            id: 'msg-1',
            content: 'hello group',
            created_at: now,
          },
        ],
      },
    ]);

    const result = await service.listConversationsForUser('user-1', 10);

    expect(result.items[0]).toMatchObject({
      id: 'group-conv-1',
      type: ConversationType.group,
      title: 'Book Club',
      groupId: 'group-1',
      groupName: 'Book Club',
      lastMessage: {
        id: 'msg-1',
        content: 'hello group',
        created_at: now,
      },
    });
  });

  it('allows current group members to send group chat messages', async () => {
    const now = new Date();
    prisma.conversations.findUnique.mockResolvedValue({
      id: 'group-conv-1',
      type: ConversationType.group,
      deleted_at: null,
      participants: [],
      group: {
        deleted_at: null,
        members: [{ user_id: 'user-1' }],
      },
    });
    prisma.messages.create.mockResolvedValue({
      id: 'msg-1',
      conversation_id: 'group-conv-1',
      sender_id: 'user-1',
      content: 'hello',
      created_at: now,
    });

    const result = await service.createMessageForConversation(
      'group-conv-1',
      'user-1',
      ' hello ',
    );

    expect(prisma.messages.create).toHaveBeenCalledWith({
      data: {
        conversation_id: 'group-conv-1',
        sender_id: 'user-1',
        content: 'hello',
      },
      include: {
        sender: true,
      },
    });
    expect(result.content).toBe('hello');
  });

  it('rejects former group members from group chat messages', async () => {
    prisma.conversations.findUnique.mockResolvedValue({
      id: 'group-conv-1',
      type: ConversationType.group,
      deleted_at: null,
      participants: [],
      group: {
        deleted_at: null,
        members: [{ user_id: 'other-user' }],
      },
    });

    await expect(
      service.createMessageForConversation('group-conv-1', 'user-1', 'hello'),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.messages.create).not.toHaveBeenCalled();
  });
});
