import {
  MomentMatchStatus,
  MomentMatchType,
  MomentOptInState,
} from '@prisma/client';
import { MatchingEngineRepository } from './matching-engine.repository';
import { MatchingEngineService } from './matching-engine.service';
import { MomentNotificationService } from './moment-notification.service';

function makeMatch(overrides: Record<string, unknown> = {}) {
  return {
    id: 'moment-1',
    match_type: MomentMatchType.friend,
    status: MomentMatchStatus.active,
    user_a_id: 'user-1',
    user_b_id: 'user-2',
    group_id: null,
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
    user_b: { id: 'user-2', username: 'ben', avatar_url: null },
    group: null,
    conversation: { id: 'conv-1', type: 'friend' },
    ...overrides,
  } as any;
}

describe('MatchingEngineService', () => {
  let service: MatchingEngineService;
  let repository: {
    findActiveMatchesForUser: jest.Mock;
    listHistoryForUser: jest.Mock;
    findActiveMatchForUserByTypeOnDay: jest.Mock;
    findReminderCandidates: jest.Mock;
    getMessageStatsForMatch: jest.Mock;
    markReminderSent: jest.Mock;
    findExpiredActiveMatches: jest.Mock;
    updateStatus: jest.Mock;
    listAcceptedFriendshipsForMatching: jest.Mock;
    listGroupMembershipsForMatching: jest.Mock;
    findRecentFriendPairing: jest.Mock;
    findAcceptedFriendshipBetween: jest.Mock;
    createMomentMatch: jest.Mock;
    findByIdForParticipant: jest.Mock;
    recordOptIn: jest.Mock;
    findDueScheduledMatches: jest.Mock;
  };
  let notifications: {
    notifyReminder: jest.Mock;
    notifyMatchStarted: jest.Mock;
  };
  let conversationsService: {
    ensureFriendConversationBetweenUsers: jest.Mock;
    createGroupPairConversationForMoment: jest.Mock;
  };

  beforeEach(() => {
    repository = {
      findActiveMatchesForUser: jest.fn(),
      listHistoryForUser: jest.fn(),
      findActiveMatchForUserByTypeOnDay: jest.fn(),
      findReminderCandidates: jest.fn(),
      getMessageStatsForMatch: jest.fn(),
      markReminderSent: jest.fn(),
      findExpiredActiveMatches: jest.fn(),
      updateStatus: jest.fn(),
      listAcceptedFriendshipsForMatching: jest.fn(),
      listGroupMembershipsForMatching: jest.fn(),
      findRecentFriendPairing: jest.fn(),
      findAcceptedFriendshipBetween: jest.fn(),
      createMomentMatch: jest.fn(),
      findByIdForParticipant: jest.fn(),
      recordOptIn: jest.fn(),
      findDueScheduledMatches: jest.fn(),
    };
    notifications = {
      notifyReminder: jest.fn(),
      notifyMatchStarted: jest.fn(),
    };
    conversationsService = {
      ensureFriendConversationBetweenUsers: jest.fn(),
      createGroupPairConversationForMoment: jest.fn(),
    };

    service = new MatchingEngineService(
      repository as unknown as MatchingEngineRepository,
      conversationsService as any,
      notifications as unknown as MomentNotificationService,
    );
  });

  it('calculates the configured UTC schedule window', () => {
    const previous = process.env.MOMENT_DAILY_TIME_UTC;
    process.env.MOMENT_DAILY_TIME_UTC = '16:30';

    const result = service.getScheduleWindow(
      new Date('2026-05-05T12:00:00.000Z'),
    );

    expect(result.scheduledDay.toISOString()).toBe(
      '2026-05-05T00:00:00.000Z',
    );
    expect(result.scheduledAt.toISOString()).toBe(
      '2026-05-05T16:30:00.000Z',
    );
    expect(result.expiresAt.toISOString()).toBe('2026-05-05T17:30:00.000Z');

    if (previous === undefined) {
      delete process.env.MOMENT_DAILY_TIME_UTC;
    } else {
      process.env.MOMENT_DAILY_TIME_UTC = previous;
    }
  });

  it('sends one reminder for inactive matches', async () => {
    const now = new Date('2026-05-05T17:35:00.000Z');
    const match = makeMatch();
    repository.findReminderCandidates.mockResolvedValue([match]);
    repository.getMessageStatsForMatch.mockResolvedValue({
      total: 0,
      bySender: new Map(),
    });

    const result = await service.sendDueReminders(now);

    expect(result).toBe(1);
    expect(notifications.notifyReminder).toHaveBeenCalledWith(match);
    expect(repository.markReminderSent).toHaveBeenCalledWith(match.id, now);
  });

  it('activates scheduled matches when their window starts', async () => {
    const scheduled = makeMatch({ status: MomentMatchStatus.scheduled });
    const active = makeMatch({ status: MomentMatchStatus.active });
    repository.findDueScheduledMatches.mockResolvedValue([scheduled]);
    repository.updateStatus.mockResolvedValue(active);

    const result = await service.activateDueMoments(
      new Date('2026-05-05T17:00:00.000Z'),
    );

    expect(result).toBe(1);
    expect(repository.updateStatus).toHaveBeenCalledWith(
      'moment-1',
      MomentMatchStatus.active,
    );
    expect(notifications.notifyMatchStarted).toHaveBeenCalledWith(active);
  });

  it('chooses today as the next schedule before the daily active time', () => {
    const result = service.getNextScheduleWindow(
      new Date('2026-05-05T02:00:00.000Z'),
    );

    expect(result.scheduledAt.toISOString()).toBe(
      '2026-05-05T16:00:00.000Z',
    );
  });

  it('chooses tomorrow as the next schedule after the daily active time', () => {
    const result = service.getNextScheduleWindow(
      new Date('2026-05-05T19:00:00.000Z'),
    );

    expect(result.scheduledAt.toISOString()).toBe(
      '2026-05-06T16:00:00.000Z',
    );
  });

  it('does not remind when a match already has activity', async () => {
    repository.findReminderCandidates.mockResolvedValue([makeMatch()]);
    repository.getMessageStatsForMatch.mockResolvedValue({
      total: 1,
      bySender: new Map([['user-1', 1]]),
    });

    const result = await service.sendDueReminders(
      new Date('2026-05-05T17:35:00.000Z'),
    );

    expect(result).toBe(0);
    expect(notifications.notifyReminder).not.toHaveBeenCalled();
    expect(repository.markReminderSent).not.toHaveBeenCalled();
  });

  it('marks due matches successful when message thresholds are met', async () => {
    repository.findExpiredActiveMatches.mockResolvedValue([makeMatch()]);
    repository.getMessageStatsForMatch.mockResolvedValue({
      total: 10,
      bySender: new Map([
        ['user-1', 9],
        ['user-2', 1],
      ]),
    });

    const result = await service.expireDueMoments(
      new Date('2026-05-05T18:01:00.000Z'),
    );

    expect(result).toEqual({ expired: 0, successful: 1 });
    expect(repository.updateStatus).toHaveBeenCalledWith(
      'moment-1',
      MomentMatchStatus.successful,
    );
  });

  it('marks due matches expired when message thresholds are not met', async () => {
    repository.findExpiredActiveMatches.mockResolvedValue([makeMatch()]);
    repository.getMessageStatsForMatch.mockResolvedValue({
      total: 10,
      bySender: new Map([['user-1', 10]]),
    });

    const result = await service.expireDueMoments(
      new Date('2026-05-05T18:01:00.000Z'),
    );

    expect(result).toEqual({ expired: 1, successful: 0 });
    expect(repository.updateStatus).toHaveBeenCalledWith(
      'moment-1',
      MomentMatchStatus.expired,
    );
  });

  it('runs retry-safe due work without creating matches before matchers are attached', async () => {
    repository.listAcceptedFriendshipsForMatching.mockResolvedValue([]);
    repository.listGroupMembershipsForMatching.mockResolvedValue([]);
    repository.findDueScheduledMatches.mockResolvedValue([]);
    repository.findReminderCandidates.mockResolvedValue([]);
    repository.findExpiredActiveMatches.mockResolvedValue([]);

    const result = await service.runDueWork(
      new Date('2026-05-05T02:00:00.000Z'),
    );

    expect(result).toMatchObject({
      created: { friend: 0, group: 0 },
      activated: 0,
      remindersSent: 0,
      expired: 0,
      successful: 0,
    });
  });

  it('runs due work and creates one friend and one group moment for eligible users', async () => {
    repository.listAcceptedFriendshipsForMatching.mockResolvedValue([
      { requester_id: 'user-1', addressee_id: 'user-2' },
    ]);
    repository.listGroupMembershipsForMatching.mockResolvedValue([
      { group_id: 'group-1', user_id: 'user-1' },
      { group_id: 'group-1', user_id: 'user-3' },
    ]);
    repository.findActiveMatchForUserByTypeOnDay.mockResolvedValue(null);
    repository.findRecentFriendPairing.mockResolvedValue(null);
    repository.findAcceptedFriendshipBetween.mockResolvedValue(null);
    repository.findReminderCandidates.mockResolvedValue([]);
    repository.findExpiredActiveMatches.mockResolvedValue([]);
    repository.findDueScheduledMatches.mockResolvedValue([]);
    conversationsService.ensureFriendConversationBetweenUsers.mockResolvedValue(
      { id: 'friend-conv-1' },
    );
    conversationsService.createGroupPairConversationForMoment.mockResolvedValue(
      { id: 'group-pair-conv-1' },
    );
    repository.createMomentMatch.mockResolvedValue(makeMatch());

    const result = await service.runDueWork(
      new Date('2026-05-05T02:00:00.000Z'),
    );

    expect(result.created.friend).toBe(1);
    expect(result.created.group).toBe(1);
    expect(result.debug).toBeUndefined();
    expect(result.scheduledAt.toISOString()).toBe(
      '2026-05-05T16:00:00.000Z',
    );
    expect(repository.createMomentMatch).toHaveBeenCalledTimes(2);
  });

  it('includes candidate diagnostics only when debug is requested', async () => {
    repository.listAcceptedFriendshipsForMatching.mockResolvedValue([
      { requester_id: 'user-1', addressee_id: 'user-2' },
    ]);
    repository.listGroupMembershipsForMatching.mockResolvedValue([]);
    repository.findActiveMatchForUserByTypeOnDay.mockResolvedValue(null);
    repository.findRecentFriendPairing.mockResolvedValue(null);
    repository.findDueScheduledMatches.mockResolvedValue([]);
    repository.findReminderCandidates.mockResolvedValue([]);
    repository.findExpiredActiveMatches.mockResolvedValue([]);
    conversationsService.ensureFriendConversationBetweenUsers.mockResolvedValue(
      { id: 'friend-conv-1' },
    );
    repository.createMomentMatch.mockResolvedValue(makeMatch());

    const result = await service.runDueWork(
      new Date('2026-05-05T02:00:00.000Z'),
      '16:00',
      true,
    );

    expect(result.debug).toEqual({
      friendCandidates: 1,
      groupCandidates: 0,
      friendSkipped: {
        alreadyPairedInRun: 0,
        existingDailyMoment: 0,
        cooldown: 0,
      },
      groupSkipped: {
        alreadyPairedInRun: 0,
        existingDailyMoment: 0,
        alreadyFriends: 0,
      },
    });
  });

  it('creates one friend moment per user and skips recent friend rematches', async () => {
    repository.listAcceptedFriendshipsForMatching.mockResolvedValue([
      {
        requester_id: 'user-1',
        addressee_id: 'user-2',
      },
      {
        requester_id: 'user-1',
        addressee_id: 'user-3',
      },
      {
        requester_id: 'user-4',
        addressee_id: 'user-5',
      },
    ]);
    repository.findActiveMatchForUserByTypeOnDay.mockResolvedValue(null);
    repository.findRecentFriendPairing
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce(makeMatch());
    conversationsService.ensureFriendConversationBetweenUsers.mockResolvedValue(
      { id: 'conv-1' },
    );
    repository.createMomentMatch.mockResolvedValue(makeMatch());

    const result = await service.createFriendMoments(
      service.getScheduleWindow(new Date('2026-05-05T17:00:00.000Z')),
    );

    expect(result.created).toBe(1);
    expect(result.candidates).toBe(3);
    expect(result.skipped.alreadyPairedInRun).toBe(1);
    expect(result.skipped.cooldown).toBe(1);
    expect(
      conversationsService.ensureFriendConversationBetweenUsers,
    ).toHaveBeenCalledWith('user-1', 'user-2');
    expect(repository.createMomentMatch).toHaveBeenCalledTimes(1);
    expect(notifications.notifyMatchStarted).not.toHaveBeenCalled();
  });

  it('creates group moments only for non-friend group members', async () => {
    repository.listGroupMembershipsForMatching.mockResolvedValue([
      { group_id: 'group-1', user_id: 'user-1' },
      { group_id: 'group-1', user_id: 'user-2' },
      { group_id: 'group-1', user_id: 'user-3' },
    ]);
    repository.findActiveMatchForUserByTypeOnDay.mockResolvedValue(null);
    repository.findAcceptedFriendshipBetween
      .mockResolvedValueOnce({ id: 'friendship-1' })
      .mockResolvedValueOnce(null);
    conversationsService.createGroupPairConversationForMoment.mockResolvedValue(
      { id: 'conv-1' },
    );
    repository.createMomentMatch.mockResolvedValue(
      makeMatch({ match_type: MomentMatchType.group }),
    );

    const result = await service.createGroupMoments(
      service.getScheduleWindow(new Date('2026-05-05T17:00:00.000Z')),
    );

    expect(result.created).toBe(1);
    expect(result.candidates).toBe(3);
    expect(result.skipped.alreadyFriends).toBe(1);
    expect(result.skipped.alreadyPairedInRun).toBe(1);
    expect(
      conversationsService.createGroupPairConversationForMoment,
    ).toHaveBeenCalledWith('user-1', 'user-3');
    expect(repository.createMomentMatch).toHaveBeenCalledWith(
      expect.objectContaining({
        matchType: MomentMatchType.group,
        groupId: 'group-1',
      }),
    );
  });

  it('records group moment opt-in for a participant', async () => {
    const match = makeMatch({ match_type: MomentMatchType.group });
    repository.findByIdForParticipant.mockResolvedValue(match);
    repository.recordOptIn.mockResolvedValue({
      ...match,
      user_a_opt_in: MomentOptInState.opted_in,
      user_b_opt_in: MomentOptInState.opted_in,
    });

    const result = await service.optInToGroupMoment('moment-1', 'user-1');

    expect(repository.recordOptIn).toHaveBeenCalledWith('moment-1', 'user-1');
    expect(result.writable).toBe(true);
  });
});
