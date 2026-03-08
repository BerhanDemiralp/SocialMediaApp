import { PrismaService } from '../prisma/prisma.service';
export declare class MatchingEngineRepository {
    private readonly prisma;
    constructor(prisma: PrismaService);
    findUsersWithoutActiveMatch(now: Date): Promise<{
        email: string;
        username: string;
        id: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    }[]>;
    findAcceptedFriends(userId: string): Promise<string[]>;
    findGroupMemberCandidates(userId: string): Promise<string[]>;
    existsMatchBetweenUsersOnDay(userAId: string, userBId: string, dayStart: Date, dayEnd: Date): Promise<boolean>;
    createMatch(userAId: string, userBId: string, matchType: 'friends' | 'groups', scheduledAt: Date): Promise<{
        id: string;
        status: string;
        match_type: string;
        scheduled_at: Date;
        expires_at: Date;
        user_a_opt_in: boolean;
        user_b_opt_in: boolean;
        user_b_id: string;
        user_a_id: string;
    }>;
    findMatchesToEvaluate(now: Date): Promise<{
        id: string;
        status: string;
        match_type: string;
        scheduled_at: Date;
        expires_at: Date;
        user_a_opt_in: boolean;
        user_b_opt_in: boolean;
        user_b_id: string;
        user_a_id: string;
    }[]>;
    getMessagesForMatchInWindow(matchId: string, start: Date, end: Date): Promise<{
        id: string;
        created_at: Date;
        content: string;
        match_id: string;
        conversation_id: string | null;
        sender_id: string;
    }[]>;
    updateMatchStatus(matchId: string, status: string): Promise<{
        id: string;
        status: string;
        match_type: string;
        scheduled_at: Date;
        expires_at: Date;
        user_a_opt_in: boolean;
        user_b_opt_in: boolean;
        user_b_id: string;
        user_a_id: string;
    }>;
    getCurrentActiveMatchForUser(userId: string, now: Date): Promise<{
        id: string;
        status: string;
        match_type: string;
        scheduled_at: Date;
        expires_at: Date;
        user_a_opt_in: boolean;
        user_b_opt_in: boolean;
        user_b_id: string;
        user_a_id: string;
    } | null>;
    getHistoricalMatchesForUser(userId: string, skip: number, take: number): Promise<{
        id: string;
        status: string;
        match_type: string;
        scheduled_at: Date;
        expires_at: Date;
        user_a_opt_in: boolean;
        user_b_opt_in: boolean;
        user_b_id: string;
        user_a_id: string;
    }[]>;
    setGroupOptIn(matchId: string, userId: string): Promise<{
        id: string;
        status: string;
        match_type: string;
        scheduled_at: Date;
        expires_at: Date;
        user_a_opt_in: boolean;
        user_b_opt_in: boolean;
        user_b_id: string;
        user_a_id: string;
    } | null>;
}
