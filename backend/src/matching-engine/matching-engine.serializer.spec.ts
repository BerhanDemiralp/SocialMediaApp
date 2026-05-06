import {
  ConversationType,
  MomentMatchStatus,
  MomentMatchType,
  MomentOptInState,
} from '@prisma/client';
import { MomentMatchWithRelations } from './matching-engine.repository';
import { serializeMomentMatch } from './matching-engine.serializer';

function makeMatch(
  overrides: Partial<MomentMatchWithRelations> = {},
): MomentMatchWithRelations {
  return {
    id: 'moment-1',
    match_type: MomentMatchType.group,
    status: MomentMatchStatus.expired,
    user_a_id: 'user-1',
    user_b_id: 'user-2',
    group_id: 'group-1',
    conversation_id: 'conv-1',
    scheduled_day: new Date('2026-05-05T00:00:00.000Z'),
    scheduled_at: new Date('2026-05-05T17:00:00.000Z'),
    expires_at: new Date('2026-05-05T18:00:00.000Z'),
    reminder_sent_at: null,
    user_a_opt_in: MomentOptInState.pending,
    user_b_opt_in: MomentOptInState.pending,
    created_at: new Date('2026-05-05T17:00:00.000Z'),
    updated_at: new Date('2026-05-05T17:00:00.000Z'),
    user_a: { id: 'user-1', username: 'alice', avatar_url: null },
    user_b: { id: 'user-2', username: 'ben', avatar_url: 'avatar.png' },
    group: { id: 'group-1', name: 'Book Club' },
    conversation: { id: 'conv-1', type: ConversationType.group_pair },
    ...overrides,
  };
}

describe('serializeMomentMatch', () => {
  it('returns shared moment fields and participant summaries', () => {
    const result = serializeMomentMatch(makeMatch());

    expect(result).toMatchObject({
      id: 'moment-1',
      matchType: MomentMatchType.group,
      status: MomentMatchStatus.expired,
      conversation_id: 'conv-1',
      group_id: 'group-1',
      group_name: 'Book Club',
      writable: false,
      participants: [
        { id: 'user-1', username: 'alice', avatar_url: null },
        { id: 'user-2', username: 'ben', avatar_url: 'avatar.png' },
      ],
    });
  });

  it('marks friend moments writable regardless of status', () => {
    const result = serializeMomentMatch(
      makeMatch({
        match_type: MomentMatchType.friend,
        group_id: null,
        group: null,
      }),
    );

    expect(result.writable).toBe(true);
  });

  it('marks group moments writable after mutual opt-in', () => {
    const result = serializeMomentMatch(
      makeMatch({
        user_a_opt_in: MomentOptInState.opted_in,
        user_b_opt_in: MomentOptInState.opted_in,
      }),
    );

    expect(result.writable).toBe(true);
  });
});
