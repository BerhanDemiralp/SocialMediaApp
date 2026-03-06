import { EventsGateway } from './events.gateway';
import { PrismaService } from '../prisma/prisma.service';
import { WsException } from '@nestjs/websockets';

describe('EventsGateway - sendMessage', () => {
  let gateway: EventsGateway;
  let prisma: {
    matches: { findUnique: jest.Mock };
    messages: { create: jest.Mock };
  };

  beforeEach(() => {
    prisma = {
      matches: { findUnique: jest.fn() },
      messages: { create: jest.fn() },
    };

    gateway = new EventsGateway(prisma as unknown as PrismaService);

    gateway.server = {
      to: jest.fn().mockReturnValue({ emit: jest.fn() }),
    } as any;
  });

  it('persists and emits message for authorized participant', async () => {
    const client: any = { user: { id: 'user-1' } };
    const data = { matchId: 'match-1', content: 'hello' };

    prisma.matches.findUnique.mockResolvedValue({
      id: 'match-1',
      user_a_id: 'user-1',
      user_b_id: 'user-2',
    });

    const storedMessage = {
      id: 'msg-1',
      match_id: 'match-1',
      sender_id: 'user-1',
      content: 'hello',
      created_at: new Date(),
    };

    prisma.messages.create.mockResolvedValue(storedMessage);

    const result = await gateway.handleMessage(client, data);

    expect(prisma.matches.findUnique).toHaveBeenCalledWith({
      where: { id: 'match-1' },
    });
    expect(prisma.messages.create).toHaveBeenCalledWith({
      data: {
        match_id: 'match-1',
        sender_id: 'user-1',
        content: 'hello',
      },
    });
    expect(gateway.server.to).toHaveBeenCalledWith('match:match-1');
    expect(result).toEqual({ event: 'messageSent', data: storedMessage });
  });

  it('throws when user is not a participant', async () => {
    const client: any = { user: { id: 'other-user' } };
    const data = { matchId: 'match-1', content: 'hello' };

    prisma.matches.findUnique.mockResolvedValue({
      id: 'match-1',
      user_a_id: 'user-1',
      user_b_id: 'user-2',
    });

    await expect(gateway.handleMessage(client, data)).rejects.toBeInstanceOf(
      WsException,
    );
    expect(prisma.messages.create).not.toHaveBeenCalled();
  });
});
