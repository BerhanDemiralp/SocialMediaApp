import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { MomentMatchStatus, MomentMatchType } from '@prisma/client';
import { ConversationsService } from '../conversations/conversations.service';
import {
  MatchingEngineRepository,
  MomentMatchWithRelations,
} from './matching-engine.repository';
import { serializeMomentMatch } from './matching-engine.serializer';
import { MomentNotificationService } from './moment-notification.service';

const DEFAULT_DAILY_TIME_UTC = '16:00';
const DEFAULT_REMINDER_AFTER_MINUTES = 30;

export interface MomentScheduleWindow {
  scheduledDay: Date;
  scheduledAt: Date;
  expiresAt: Date;
}

export interface MomentRunResult {
  scheduledAt: Date;
  expiresAt: Date;
  created: {
    friend: number;
    group: number;
  };
  activated: number;
  remindersSent: number;
  expired: number;
  successful: number;
  debug?: {
    friendCandidates: number;
    groupCandidates: number;
    friendSkipped: Record<string, number>;
    groupSkipped: Record<string, number>;
  };
}

interface MomentCreationStats {
  created: number;
  candidates: number;
  skipped: Record<string, number>;
}

@Injectable()
export class MatchingEngineService {
  constructor(
    private readonly repository: MatchingEngineRepository,
    private readonly conversationsService: ConversationsService,
    private readonly notifications: MomentNotificationService,
  ) {}

  async getCurrentMomentsForUser(userId: string) {
    await this.activateDueMoments();
    const matches = await this.repository.findActiveMatchesForUser(userId);
    return matches.map(serializeMomentMatch);
  }

  async getMomentHistoryForUser(userId: string, limit?: number, cursor?: string) {
    const matches = await this.repository.listHistoryForUser(
      userId,
      limit,
      cursor,
    );
    const take = limit && limit > 0 ? limit : 20;

    return {
      items: matches.map(serializeMomentMatch),
      nextCursor: matches.length === take ? matches[matches.length - 1]?.id : null,
    };
  }

  async hasActiveMatchForType(
    userId: string,
    matchType: MomentMatchType,
    scheduledDay: Date,
  ) {
    const match = await this.repository.findActiveMatchForUserByTypeOnDay(
      userId,
      matchType,
      scheduledDay,
    );
    return !!match;
  }

  async optInToGroupMoment(matchId: string, userId: string) {
    const match = await this.repository.findByIdForParticipant(matchId, userId);

    if (!match) {
      throw new NotFoundException('Moment match not found');
    }

    if (match.match_type !== MomentMatchType.group) {
      throw new BadRequestException('Only group Moments support opt-in');
    }

    const updated = await this.repository.recordOptIn(matchId, userId);

    if (!updated) {
      throw new ForbiddenException('You are not a participant of this Moment');
    }

    return serializeMomentMatch(updated);
  }

  getScheduleWindow(
    now = new Date(),
    dailyTimeUtc = process.env.MOMENT_DAILY_TIME_UTC ?? DEFAULT_DAILY_TIME_UTC,
  ): MomentScheduleWindow {
    const configuredTime =
      this.normalizeDailyTimeUtc(dailyTimeUtc);
    const [hourText, minuteText] = configuredTime.split(':');
    const hour = Number(hourText);
    const minute = Number(minuteText);

    const scheduledDay = new Date(
      Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()),
    );

    const scheduledAt = new Date(scheduledDay);
    scheduledAt.setUTCHours(
      Number.isInteger(hour) ? hour : 17,
      Number.isInteger(minute) ? minute : 0,
      0,
      0,
    );

    const expiresAt = new Date(scheduledAt.getTime() + 60 * 60 * 1000);

    return { scheduledDay, scheduledAt, expiresAt };
  }

  getNextScheduleWindow(
    now = new Date(),
    dailyTimeUtc = process.env.MOMENT_DAILY_TIME_UTC ?? DEFAULT_DAILY_TIME_UTC,
  ): MomentScheduleWindow {
    const todayWindow = this.getScheduleWindow(now, dailyTimeUtc);

    if (now.getTime() < todayWindow.scheduledAt.getTime()) {
      return todayWindow;
    }

    const tomorrow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    return this.getScheduleWindow(tomorrow, dailyTimeUtc);
  }

  async runDueWork(
    now = new Date(),
    dailyTimeUtc = process.env.MOMENT_DAILY_TIME_UTC ?? DEFAULT_DAILY_TIME_UTC,
    includeDebug = false,
  ): Promise<MomentRunResult> {
    const creationWindow = this.getNextScheduleWindow(now, dailyTimeUtc);
    const created = await this.createDailyMoments(creationWindow);

    const [activated, remindersSent, expiration] = await Promise.all([
      this.activateDueMoments(now),
      this.sendDueReminders(now),
      this.expireDueMoments(now),
    ]);

    const result: MomentRunResult = {
      scheduledAt: creationWindow.scheduledAt,
      expiresAt: creationWindow.expiresAt,
      created: {
        friend: created.friend.created,
        group: created.group.created,
      },
      activated,
      remindersSent,
      expired: expiration.expired,
      successful: expiration.successful,
    };

    if (includeDebug) {
      result.debug = {
        friendCandidates: created.friend.candidates,
        groupCandidates: created.group.candidates,
        friendSkipped: created.friend.skipped,
        groupSkipped: created.group.skipped,
      };
    }

    return result;
  }

  private normalizeDailyTimeUtc(value: string) {
    if (/^\d{2}:\d{2}$/.test(value)) {
      return value;
    }

    return DEFAULT_DAILY_TIME_UTC;
  }

  async activateDueMoments(now = new Date()) {
    const matches = await this.repository.findDueScheduledMatches(now);
    let activated = 0;

    for (const match of matches) {
      const activatedMatch = await this.repository.updateStatus(
        match.id,
        MomentMatchStatus.active,
      );
      await this.notifications.notifyMatchStarted(activatedMatch);
      activated += 1;
    }

    return activated;
  }

  async createDailyMoments(window: MomentScheduleWindow) {
    const friend = await this.createFriendMoments(window);
    const group = await this.createGroupMoments(window);

    return { friend, group };
  }

  async createFriendMoments(window: MomentScheduleWindow): Promise<MomentCreationStats> {
    const friendships =
      await this.repository.listAcceptedFriendshipsForMatching();
    const pairedUsers = new Set<string>();
    const stats: MomentCreationStats = {
      created: 0,
      candidates: friendships.length,
      skipped: {
        alreadyPairedInRun: 0,
        existingDailyMoment: 0,
        cooldown: 0,
      },
    };
    const cooldownSince = new Date(
      window.scheduledAt.getTime() - 7 * 24 * 60 * 60 * 1000,
    );

    for (const friendship of friendships) {
      const userAId = friendship.requester_id;
      const userBId = friendship.addressee_id;

      if (pairedUsers.has(userAId) || pairedUsers.has(userBId)) {
        stats.skipped.alreadyPairedInRun += 1;
        continue;
      }

      const [userAActive, userBActive, recentPairing] = await Promise.all([
        this.hasActiveMatchForType(
          userAId,
          MomentMatchType.friend,
          window.scheduledDay,
        ),
        this.hasActiveMatchForType(
          userBId,
          MomentMatchType.friend,
          window.scheduledDay,
        ),
        this.repository.findRecentFriendPairing(
          userAId,
          userBId,
          cooldownSince,
        ),
      ]);

      if (userAActive || userBActive || recentPairing) {
        if (userAActive || userBActive) {
          stats.skipped.existingDailyMoment += 1;
        } else {
          stats.skipped.cooldown += 1;
        }
        continue;
      }

      const conversation =
        await this.conversationsService.ensureFriendConversationBetweenUsers(
          userAId,
          userBId,
        );

      await this.repository.createMomentMatch({
        matchType: MomentMatchType.friend,
        userAId,
        userBId,
        conversationId: conversation.id,
        scheduledDay: window.scheduledDay,
        scheduledAt: window.scheduledAt,
        expiresAt: window.expiresAt,
      });

      pairedUsers.add(userAId);
      pairedUsers.add(userBId);
      stats.created += 1;
    }

    return stats;
  }

  async createGroupMoments(window: MomentScheduleWindow): Promise<MomentCreationStats> {
    const memberships = await this.repository.listGroupMembershipsForMatching();
    const pairedUsers = new Set<string>();
    const stats: MomentCreationStats = {
      created: 0,
      candidates: 0,
      skipped: {
        alreadyPairedInRun: 0,
        existingDailyMoment: 0,
        alreadyFriends: 0,
      },
    };

    const membershipsByGroup = new Map<string, typeof memberships>();

    for (const membership of memberships) {
      const existing = membershipsByGroup.get(membership.group_id) ?? [];
      existing.push(membership);
      membershipsByGroup.set(membership.group_id, existing);
    }

    for (const groupMemberships of membershipsByGroup.values()) {
      for (let i = 0; i < groupMemberships.length; i += 1) {
        for (let j = i + 1; j < groupMemberships.length; j += 1) {
          const userAId = groupMemberships[i].user_id;
          const userBId = groupMemberships[j].user_id;
          stats.candidates += 1;

          if (pairedUsers.has(userAId) || pairedUsers.has(userBId)) {
            stats.skipped.alreadyPairedInRun += 1;
            continue;
          }

          const [userAActive, userBActive, friendship] = await Promise.all([
            this.hasActiveMatchForType(
              userAId,
              MomentMatchType.group,
              window.scheduledDay,
            ),
            this.hasActiveMatchForType(
              userBId,
              MomentMatchType.group,
              window.scheduledDay,
            ),
            this.repository.findAcceptedFriendshipBetween(userAId, userBId),
          ]);

          if (userAActive || userBActive || friendship) {
            if (userAActive || userBActive) {
              stats.skipped.existingDailyMoment += 1;
            } else {
              stats.skipped.alreadyFriends += 1;
            }
            continue;
          }

          const conversation =
            await this.conversationsService.createGroupPairConversationForMoment(
              userAId,
              userBId,
            );

          await this.repository.createMomentMatch({
            matchType: MomentMatchType.group,
            userAId,
            userBId,
            groupId: groupMemberships[i].group_id,
            conversationId: conversation.id,
            scheduledDay: window.scheduledDay,
            scheduledAt: window.scheduledAt,
            expiresAt: window.expiresAt,
          });

          pairedUsers.add(userAId);
          pairedUsers.add(userBId);
          stats.created += 1;
        }
      }
    }

    return stats;
  }

  async sendDueReminders(now = new Date()) {
    const reminderAfterMinutes = Number(
      process.env.MOMENT_REMINDER_AFTER_MINUTES ??
        DEFAULT_REMINDER_AFTER_MINUTES,
    );
    const inactiveSince = new Date(
      now.getTime() - reminderAfterMinutes * 60 * 1000,
    );
    const candidates = await this.repository.findReminderCandidates(
      now,
      inactiveSince,
    );

    let remindersSent = 0;

    for (const match of candidates) {
      const stats = await this.repository.getMessageStatsForMatch(match);

      if (stats.total > 0) {
        continue;
      }

      await this.notifications.notifyReminder(match);
      await this.repository.markReminderSent(match.id, now);
      remindersSent += 1;
    }

    return remindersSent;
  }

  async expireDueMoments(now = new Date()) {
    const matches = await this.repository.findExpiredActiveMatches(now);
    let expired = 0;
    let successful = 0;

    for (const match of matches) {
      const isSuccessful = await this.isMatchSuccessful(match);

      if (isSuccessful) {
        await this.repository.updateStatus(
          match.id,
          MomentMatchStatus.successful,
        );
        successful += 1;
      } else {
        await this.repository.updateStatus(match.id, MomentMatchStatus.expired);
        expired += 1;
      }
    }

    return { expired, successful };
  }

  private async isMatchSuccessful(match: MomentMatchWithRelations) {
    const stats = await this.repository.getMessageStatsForMatch(match);
    const userAMessageCount = stats.bySender.get(match.user_a_id) ?? 0;
    const userBMessageCount = stats.bySender.get(match.user_b_id) ?? 0;

    return stats.total >= 10 && userAMessageCount > 0 && userBMessageCount > 0;
  }
}
