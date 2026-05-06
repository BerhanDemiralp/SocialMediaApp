import {
  MomentMatchStatus,
  MomentMatchType,
  MomentOptInState,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { MatchingEngineRepository } from './matching-engine.repository';

describe('MatchingEngineRepository', () => {
  let repository: MatchingEngineRepository;
  let prisma: {
    moment_matches: {
      create: jest.Mock;
      findMany: jest.Mock;
      findFirst: jest.Mock;
      findUnique: jest.Mock;
      update: jest.Mock;
    };
    messages: {
      groupBy: jest.Mock;
    };
  };

  beforeEach(() => {
    prisma = {
      moment_matches: {
        create: jest.fn(),
        findMany: jest.fn(),
        findFirst: jest.fn(),
        findUnique: jest.fn(),
        update: jest.fn(),
      },
      messages: {
        groupBy: jest.fn(),
      },
    };

    repository = new MatchingEngineRepository(
      prisma as unknown as PrismaService,
    );
  });

  it('creates a moment match with lifecycle fields', async () => {
    const scheduledAt = new Date('2026-05-05T17:00:00.000Z');
    const expiresAt = new Date('2026-05-05T18:00:00.000Z');
    const scheduledDay = new Date('2026-05-05T00:00:00.000Z');
    prisma.moment_matches.create.mockResolvedValue({ id: 'moment-1' });

    await repository.createMomentMatch({
      matchType: MomentMatchType.friend,
      userAId: 'user-1',
      userBId: 'user-2',
      conversationId: 'conv-1',
      scheduledDay,
      scheduledAt,
      expiresAt,
    });

    expect(prisma.moment_matches.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          match_type: MomentMatchType.friend,
          user_a_id: 'user-1',
          user_b_id: 'user-2',
          conversation_id: 'conv-1',
          scheduled_day: scheduledDay,
          scheduled_at: scheduledAt,
          expires_at: expiresAt,
        }),
      }),
    );
  });

  it('finds active matches for a participant and optional type', async () => {
    prisma.moment_matches.findMany.mockResolvedValue([]);

    await repository.findActiveMatchesForUser(
      'user-1',
      MomentMatchType.group,
    );

    expect(prisma.moment_matches.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: MomentMatchStatus.active,
          match_type: MomentMatchType.group,
          OR: [{ user_a_id: 'user-1' }, { user_b_id: 'user-1' }],
        }),
      }),
    );
  });

  it('looks up recent friend pairings in either participant order', async () => {
    const since = new Date('2026-05-01T00:00:00.000Z');
    prisma.moment_matches.findFirst.mockResolvedValue(null);

    await repository.findRecentFriendPairing('user-1', 'user-2', since);

    expect(prisma.moment_matches.findFirst).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          match_type: MomentMatchType.friend,
          scheduled_at: { gte: since },
          OR: [
            { user_a_id: 'user-1', user_b_id: 'user-2' },
            { user_a_id: 'user-2', user_b_id: 'user-1' },
          ],
        }),
      }),
    );
  });

  it('updates status and reminder state', async () => {
    const sentAt = new Date('2026-05-05T17:20:00.000Z');
    prisma.moment_matches.update.mockResolvedValue({ id: 'moment-1' });

    await repository.updateStatus('moment-1', MomentMatchStatus.successful);
    await repository.markReminderSent('moment-1', sentAt);

    expect(prisma.moment_matches.update).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        where: { id: 'moment-1' },
        data: { status: MomentMatchStatus.successful },
      }),
    );
    expect(prisma.moment_matches.update).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        where: { id: 'moment-1' },
        data: { reminder_sent_at: sentAt },
      }),
    );
  });

  it('records opt-in only for participants', async () => {
    prisma.moment_matches.findUnique.mockResolvedValue({
      user_a_id: 'user-1',
      user_b_id: 'user-2',
    });
    prisma.moment_matches.update.mockResolvedValue({ id: 'moment-1' });

    await repository.recordOptIn('moment-1', 'user-2');

    expect(prisma.moment_matches.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: { user_b_opt_in: MomentOptInState.opted_in },
      }),
    );

    prisma.moment_matches.update.mockClear();
    await expect(
      repository.recordOptIn('moment-1', 'user-3'),
    ).resolves.toBeNull();
    expect(prisma.moment_matches.update).not.toHaveBeenCalled();
  });

  it('aggregates message stats by sender for a match window', async () => {
    prisma.messages.groupBy.mockResolvedValue([
      { sender_id: 'user-1', _count: { _all: 7 } },
      { sender_id: 'user-2', _count: { _all: 3 } },
    ]);
    const scheduledAt = new Date('2026-05-05T17:00:00.000Z');
    const expiresAt = new Date('2026-05-05T18:00:00.000Z');

    const result = await repository.getMessageStatsForMatch({
      conversation_id: 'conv-1',
      scheduled_at: scheduledAt,
      expires_at: expiresAt,
    });

    expect(prisma.messages.groupBy).toHaveBeenCalledWith({
      by: ['sender_id'],
      where: {
        conversation_id: 'conv-1',
        deleted_at: null,
        created_at: {
          gte: scheduledAt,
          lte: expiresAt,
        },
      },
      _count: {
        _all: true,
      },
    });
    expect(result.total).toBe(10);
    expect(result.bySender.get('user-1')).toBe(7);
    expect(result.bySender.get('user-2')).toBe(3);
  });
});
