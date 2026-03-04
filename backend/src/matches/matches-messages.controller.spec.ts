import { MatchesMessagesController } from './matches-messages.controller';
import { PrismaService } from '../prisma/prisma.service';
import { ForbiddenException } from '@nestjs/common';

describe('MatchesMessagesController', () => {
  let controller: MatchesMessagesController;
  let prisma: {
    matches: { findUnique: jest.Mock };
    messages: { findMany: jest.Mock };
  };

  beforeEach(() => {
    prisma = {
      matches: { findUnique: jest.fn() },
      messages: { findMany: jest.fn() },
    };

    controller = new MatchesMessagesController(
      prisma as unknown as PrismaService,
    );
  });

  it('returns messages for authorized participant with limit', async () => {
    const req: any = { user: { id: 'user-1' } };

    prisma.matches.findUnique.mockResolvedValue({
      id: 'match-1',
      user_a_id: 'user-1',
      user_b_id: 'user-2',
    });

    const messages = [
      {
        id: 'msg-1',
        match_id: 'match-1',
        sender_id: 'user-1',
        content: 'hi',
        created_at: new Date(),
      },
    ];

    prisma.messages.findMany.mockResolvedValue(messages);

    const result = await controller.getMatchMessages('match-1', req, 10);

    expect(prisma.matches.findUnique).toHaveBeenCalledWith({
      where: { id: 'match-1' },
    });
    expect(prisma.messages.findMany).toHaveBeenCalledWith({
      where: { match_id: 'match-1' },
      orderBy: { created_at: 'asc' },
      take: 10,
    });
    expect(result).toEqual(messages);
  });

  it('throws Forbidden for non-participant', async () => {
    const req: any = { user: { id: 'other-user' } };

    prisma.matches.findUnique.mockResolvedValue({
      id: 'match-1',
      user_a_id: 'user-1',
      user_b_id: 'user-2',
    });

    await expect(
      controller.getMatchMessages('match-1', req, undefined),
    ).rejects.toBeInstanceOf(ForbiddenException);
    expect(prisma.messages.findMany).not.toHaveBeenCalled();
  });
});
