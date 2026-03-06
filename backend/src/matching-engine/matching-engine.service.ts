import { Injectable } from '@nestjs/common';
import { MatchingEngineRepository } from './matching-engine.repository';

@Injectable()
export class MatchingEngineService {
  constructor(
    private readonly matchingEngineRepository: MatchingEngineRepository,
  ) {}

  private getDayRange(now: Date) {
    const start = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), now.getUTCDate()));
    const end = new Date(start);
    end.setUTCDate(end.getUTCDate() + 1);
    return { start, end };
  }

  async runDailyMatching(now: Date) {
    // First, evaluate any matches whose 1-hour window has ended.
    await this.evaluateExpiredMatches(now);

    const { start, end } = this.getDayRange(now);
    const users = await this.matchingEngineRepository.findUsersWithoutActiveMatch(
      now,
    );

    const assigned = new Set<string>();
    const created = [];

    for (const user of users) {
      if (assigned.has(user.id)) {
        continue;
      }

      const friendIds =
        await this.matchingEngineRepository.findAcceptedFriends(user.id);

      let partnerId: string | null = null;
      let matchType: 'friends' | 'groups' | null = null;

      // Prefer friends first.
      for (const fid of friendIds) {
        if (assigned.has(fid)) {
          continue;
        }
        const exists =
          await this.matchingEngineRepository.existsMatchBetweenUsersOnDay(
            user.id,
            fid,
            start,
            end,
          );
        if (!exists) {
          partnerId = fid;
          matchType = 'friends';
          break;
        }
      }

      // If no friend candidate, fall back to group members.
      if (!partnerId) {
        const groupCandidateIds =
          await this.matchingEngineRepository.findGroupMemberCandidates(
            user.id,
          );

        for (const gid of groupCandidateIds) {
          if (assigned.has(gid)) {
            continue;
          }
          const exists =
            await this.matchingEngineRepository.existsMatchBetweenUsersOnDay(
              user.id,
              gid,
              start,
              end,
            );
          if (!exists) {
            partnerId = gid;
            matchType = 'groups';
            break;
          }
        }
      }

      if (partnerId && matchType) {
        const match = await this.matchingEngineRepository.createMatch(
          user.id,
          partnerId,
          matchType,
          now,
        );
        created.push(match);
        assigned.add(user.id);
        assigned.add(partnerId);
      }
    }

    return { createdCount: created.length };
  }

  async evaluateExpiredMatches(now: Date) {
    const matches = await this.matchingEngineRepository.findMatchesToEvaluate(
      now,
    );

    for (const match of matches) {
      const messages =
        await this.matchingEngineRepository.getMessagesForMatchInWindow(
          match.id,
          match.scheduled_at,
          match.expires_at,
        );

      const totalMessages = messages.length;
      const byUser = new Map<string, number>();

      for (const message of messages) {
        const current = byUser.get(message.sender_id) ?? 0;
        byUser.set(message.sender_id, current + 1);
      }

      const userAMessages = byUser.get(match.user_a_id) ?? 0;
      const userBMessages = byUser.get(match.user_b_id) ?? 0;

      const isSuccessful =
        totalMessages >= 10 && userAMessages >= 1 && userBMessages >= 1;

      await this.matchingEngineRepository.updateMatchStatus(
        match.id,
        isSuccessful ? 'successful' : 'expired',
      );
    }
  }

  async getCurrentMomentForUser(userId: string, now: Date) {
    return this.matchingEngineRepository.getCurrentActiveMatchForUser(
      userId,
      now,
    );
  }

  async getMatchHistoryForUser(
    userId: string,
    page: number,
    pageSize: number,
  ) {
    const take = pageSize;
    const skip = (page - 1) * pageSize;
    return this.matchingEngineRepository.getHistoricalMatchesForUser(
      userId,
      skip,
      take,
    );
  }

  async optInToGroupMatch(matchId: string, userId: string) {
    return this.matchingEngineRepository.setGroupOptIn(matchId, userId);
  }
}

