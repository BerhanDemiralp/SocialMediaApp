import {
  BadRequestException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { MomentMatchStatus, MomentMatchType } from '@prisma/client';
import { ConversationsService } from '../conversations/conversations.service';
import { FriendsService } from '../friends/friends.service';
import {
  MatchingEngineRepository,
  MomentMatchWithRelations,
} from './matching-engine.repository';
import { serializeMomentMatch } from './matching-engine.serializer';
import { MomentNotificationService } from './moment-notification.service';

const DEFAULT_DAILY_TIME_LOCAL = '19:00';
const DEFAULT_TIMEZONE = 'Europe/Istanbul';
const DEFAULT_REMINDER_AFTER_MINUTES = 30;
const DEFAULT_ACTIVE_DURATION_MINUTES = 60;

export interface MomentScheduleWindow {
  scheduledDay: Date;
  scheduledAt: Date;
  expiresAt: Date;
}

export interface MatchingRuntimeSettings {
  dailyTimeLocal: string;
  timezone: string;
  enabled: boolean;
  reminderAfterMinutes: number;
  activeDurationMinutes: number;
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

export interface MomentCreationRunResult {
  scheduledAt: Date;
  expiresAt: Date;
  created: {
    friend: number;
    group: number;
  };
  debug?: {
    friendCandidates: number;
    groupCandidates: number;
    friendSkipped: Record<string, number>;
    groupSkipped: Record<string, number>;
  };
}

export interface MomentStatusRunResult {
  activated: number;
  remindersSent: number;
  expired: number;
  successful: number;
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
    private readonly friendsService: FriendsService,
    private readonly notifications: MomentNotificationService,
  ) {}

  async getCurrentMomentsForUser(userId: string) {
    await this.runStatusWork();
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

  async respondToGroupMomentFriendship(
    matchId: string,
    userId: string,
    wantsFriend: boolean,
  ) {
    const match = await this.repository.findByIdForParticipant(matchId, userId);

    if (!match) {
      throw new NotFoundException('Moment match not found');
    }

    if (match.match_type !== MomentMatchType.group) {
      throw new BadRequestException(
        'Only successful group Moments support friendship consent',
      );
    }

    if (match.status !== MomentMatchStatus.successful) {
      throw new BadRequestException(
        'Only successful group Moments support friendship consent',
      );
    }

    if (
      match.user_a_friend_consent === true &&
      match.user_b_friend_consent === true
    ) {
      const { conversation } =
        await this.friendsService.createAcceptedFriendshipFromMoment(
          match.user_a_id,
          match.user_b_id,
        );

      return {
        friendshipCreated: true,
        friendshipRemoved: false,
        locked: true,
        conversation,
        moment: serializeMomentMatch(match),
      };
    }

    const updated = await this.repository.recordFriendConsent(
      matchId,
      userId,
      wantsFriend,
    );

    if (!updated) {
      throw new ForbiddenException('You are not a participant of this Moment');
    }

    const bothWantFriend =
      updated.user_a_friend_consent === true &&
      updated.user_b_friend_consent === true;

    if (!bothWantFriend) {
      if (!wantsFriend) {
        await this.friendsService.removeAcceptedFriendshipFromMoment(
          updated.user_a_id,
          updated.user_b_id,
        );
      }

      return {
        friendshipCreated: false,
        friendshipRemoved: !wantsFriend,
        locked: false,
        moment: serializeMomentMatch(updated),
      };
    }

    const { conversation } =
      await this.friendsService.createAcceptedFriendshipFromMoment(
        updated.user_a_id,
        updated.user_b_id,
      );

    return {
      friendshipCreated: true,
      friendshipRemoved: false,
      locked: true,
      conversation,
      moment: serializeMomentMatch(updated),
    };
  }

  async getSettings() {
    const settings = await this.repository.getMatchingSettings();

    return {
      dailyTimeLocal: settings.daily_time_local,
      timezone: settings.timezone,
      enabled: settings.enabled,
      reminderAfterMinutes: settings.reminder_after_min,
      activeDurationMinutes: settings.active_duration_min,
      updated_at: settings.updated_at,
    };
  }

  async updateSettings(input: {
    dailyTimeLocal?: string;
    timezone?: string;
    enabled?: boolean;
    reminderAfterMinutes?: number;
    activeDurationMinutes?: number;
  }) {
    const timezone =
      input.timezone !== undefined
        ? this.normalizeTimezone(input.timezone)
        : undefined;
    const settings = await this.repository.updateMatchingSettings({
      ...input,
      dailyTimeLocal:
        input.dailyTimeLocal !== undefined
          ? this.normalizeDailyTimeLocal(input.dailyTimeLocal)
          : undefined,
      timezone,
    });

    return {
      dailyTimeLocal: settings.daily_time_local,
      timezone: settings.timezone,
      enabled: settings.enabled,
      reminderAfterMinutes: settings.reminder_after_min,
      activeDurationMinutes: settings.active_duration_min,
      updated_at: settings.updated_at,
    };
  }

  getScheduleWindow(
    now = new Date(),
    dailyTimeLocal = DEFAULT_DAILY_TIME_LOCAL,
    timezone = DEFAULT_TIMEZONE,
    activeDurationMinutes = DEFAULT_ACTIVE_DURATION_MINUTES,
  ): MomentScheduleWindow {
    const configuredTime = this.normalizeDailyTimeLocal(dailyTimeLocal);
    const configuredTimezone = this.normalizeTimezone(timezone);
    const [hourText, minuteText] = configuredTime.split(':');
    const hour = Number(hourText);
    const minute = Number(minuteText);
    const localDate = this.getZonedDateParts(now, configuredTimezone);

    const scheduledDay = new Date(
      Date.UTC(localDate.year, localDate.month - 1, localDate.day),
    );

    const scheduledAt = this.zonedLocalTimeToUtc(
      localDate.year,
      localDate.month,
      localDate.day,
      Number.isInteger(hour) ? hour : 17,
      Number.isInteger(minute) ? minute : 0,
      configuredTimezone,
    );

    const normalizedDuration =
      Number.isInteger(activeDurationMinutes) && activeDurationMinutes > 0
        ? activeDurationMinutes
        : DEFAULT_ACTIVE_DURATION_MINUTES;
    const expiresAt = new Date(
      scheduledAt.getTime() + normalizedDuration * 60 * 1000,
    );

    return { scheduledDay, scheduledAt, expiresAt };
  }

  getNextScheduleWindow(
    now = new Date(),
    dailyTimeLocal = DEFAULT_DAILY_TIME_LOCAL,
    timezone = DEFAULT_TIMEZONE,
    activeDurationMinutes = DEFAULT_ACTIVE_DURATION_MINUTES,
  ): MomentScheduleWindow {
    const configuredTimezone = this.normalizeTimezone(timezone);
    const todayWindow = this.getScheduleWindow(
      now,
      dailyTimeLocal,
      configuredTimezone,
      activeDurationMinutes,
    );

    if (now.getTime() < todayWindow.expiresAt.getTime()) {
      return todayWindow;
    }

    const localDate = this.getZonedDateParts(now, configuredTimezone);
    const tomorrowUtc = new Date(
      Date.UTC(localDate.year, localDate.month - 1, localDate.day) +
        24 * 60 * 60 * 1000,
    );
    return this.getScheduleWindow(
      tomorrowUtc,
      dailyTimeLocal,
      configuredTimezone,
      activeDurationMinutes,
    );
  }

  async runDueWork(
    now = new Date(),
    dailyTimeOverride?: string,
    includeDebug = false,
  ): Promise<MomentRunResult> {
    const [creation, status] = await Promise.all([
      this.runCreationWork(now, dailyTimeOverride, includeDebug),
      this.runStatusWork(now),
    ]);

    const result: MomentRunResult = {
      scheduledAt: creation.scheduledAt,
      expiresAt: creation.expiresAt,
      created: creation.created,
      activated: status.activated,
      remindersSent: status.remindersSent,
      expired: status.expired,
      successful: status.successful,
    };

    if (creation.debug) {
      result.debug = creation.debug;
    }

    return result;
  }

  async runCreationWork(
    now = new Date(),
    dailyTimeOverride?: string,
    includeDebug = false,
  ): Promise<MomentCreationRunResult> {
    const settings = await this.getRuntimeSettings(dailyTimeOverride);
    const creationWindow = this.getNextScheduleWindow(
      now,
      settings.dailyTimeLocal,
      settings.timezone,
      settings.activeDurationMinutes,
    );

    if (!settings.enabled) {
      return {
        scheduledAt: creationWindow.scheduledAt,
        expiresAt: creationWindow.expiresAt,
        created: {
          friend: 0,
          group: 0,
        },
      };
    }

    const created = await this.createDailyMoments(creationWindow);
    const result: MomentCreationRunResult = {
      scheduledAt: creationWindow.scheduledAt,
      expiresAt: creationWindow.expiresAt,
      created: {
        friend: created.friend.created,
        group: created.group.created,
      },
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

  async runStatusWork(now = new Date()): Promise<MomentStatusRunResult> {
    const settings = await this.getRuntimeSettings();

    if (!settings.enabled) {
      return {
        activated: 0,
        remindersSent: 0,
        expired: 0,
        successful: 0,
      };
    }

    const activated = await this.activateDueMoments(now);
    const [earlySuccessful, remindersSent, expiration] = await Promise.all([
      this.markSuccessfulActiveMoments(now),
      this.sendDueReminders(now, settings.reminderAfterMinutes),
      this.expireDueMoments(now),
    ]);

    return {
      activated,
      remindersSent,
      expired: expiration.expired,
      successful: earlySuccessful + expiration.successful,
    };
  }

  async hasStatusWorkCandidates(now = new Date()) {
    return this.repository.hasStatusWorkCandidates(now);
  }

  private normalizeDailyTimeLocal(value: string) {
    const normalizedValue = value.trim().replace('.', ':');
    const match = /^(\d{1,2}):(\d{2})$/.exec(normalizedValue);

    if (!match) {
      throw new BadRequestException('dailyTimeLocal must use HH:mm format');
    }

    const hour = Number(match[1]);
    const minute = Number(match[2]);

    if (hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw new BadRequestException('dailyTimeLocal must be a valid 24-hour time');
    }

    return `${hour.toString().padStart(2, '0')}:${minute
      .toString()
      .padStart(2, '0')}`;
  }

  private normalizeTimezone(value: string) {
    try {
      new Intl.DateTimeFormat('en-US', { timeZone: value }).format(new Date());
      return value;
    } catch {
      throw new BadRequestException('timezone must be a valid IANA timezone');
    }
  }

  private getZonedDateParts(date: Date, timezone: string) {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: timezone,
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    });
    const parts = Object.fromEntries(
      formatter.formatToParts(date).map((part) => [part.type, part.value]),
    );

    return {
      year: Number(parts.year),
      month: Number(parts.month),
      day: Number(parts.day),
      hour: Number(parts.hour),
      minute: Number(parts.minute),
      second: Number(parts.second),
    };
  }

  private zonedLocalTimeToUtc(
    year: number,
    month: number,
    day: number,
    hour: number,
    minute: number,
    timezone: string,
  ) {
    const desiredWallTime = Date.UTC(year, month - 1, day, hour, minute, 0, 0);
    let utcTime = desiredWallTime;

    for (let attempt = 0; attempt < 3; attempt += 1) {
      const zoned = this.getZonedDateParts(new Date(utcTime), timezone);
      const actualWallTime = Date.UTC(
        zoned.year,
        zoned.month - 1,
        zoned.day,
        zoned.hour,
        zoned.minute,
        zoned.second,
        0,
      );
      const diff = desiredWallTime - actualWallTime;

      if (diff === 0) {
        break;
      }

      utcTime += diff;
    }

    return new Date(utcTime);
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

  async sendDueReminders(
    now = new Date(),
    configuredReminderAfterMinutes?: number,
  ) {
    const reminderAfterMinutes =
      configuredReminderAfterMinutes ??
      Number(
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

  async markSuccessfulActiveMoments(now = new Date()) {
    const matches = await this.repository.findActiveMatchesForSuccessCheck(now);
    let successful = 0;

    for (const match of matches) {
      const isSuccessful = await this.isMatchSuccessful(match);

      if (!isSuccessful) {
        continue;
      }

      await this.repository.updateStatus(match.id, MomentMatchStatus.successful);
      successful += 1;
    }

    return successful;
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

  async getRuntimeSettings(
    dailyTimeOverride?: string,
  ): Promise<MatchingRuntimeSettings> {
    const settings = await this.repository.getMatchingSettings();

    return {
      dailyTimeLocal:
        dailyTimeOverride ??
        settings.daily_time_local ??
        DEFAULT_DAILY_TIME_LOCAL,
      timezone: settings.timezone ?? DEFAULT_TIMEZONE,
      enabled: settings.enabled,
      reminderAfterMinutes:
        settings.reminder_after_min ?? DEFAULT_REMINDER_AFTER_MINUTES,
      activeDurationMinutes:
        settings.active_duration_min ?? DEFAULT_ACTIVE_DURATION_MINUTES,
    };
  }
}
