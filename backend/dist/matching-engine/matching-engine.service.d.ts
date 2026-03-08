import { MatchingEngineRepository } from './matching-engine.repository';
export declare class MatchingEngineService {
    private readonly matchingEngineRepository;
    constructor(matchingEngineRepository: MatchingEngineRepository);
    private getDayRange;
    runDailyMatching(now: Date): Promise<{
        createdCount: number;
    }>;
    evaluateExpiredMatches(now: Date): Promise<void>;
    getCurrentMomentForUser(userId: string, now: Date): Promise<{
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
    getMatchHistoryForUser(userId: string, page: number, pageSize: number): Promise<{
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
    optInToGroupMatch(matchId: string, userId: string): Promise<{
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
