import { Request as ExpressRequest } from 'express';
import { MatchingEngineService } from './matching-engine.service';
export declare class MatchingEngineController {
    private readonly matchingEngineService;
    constructor(matchingEngineService: MatchingEngineService);
    runMatching(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }): Promise<{
        createdCount: number;
    }>;
    getCurrentMoment(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }): Promise<{
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
    getHistory(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, page?: string, pageSize?: string): Promise<{
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
    optInToGroupMatch(matchId: string, req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, optIn?: boolean): Promise<{
        message: string;
    }>;
}
