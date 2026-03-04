import { Request as ExpressRequest } from 'express';
import { PrismaService } from '../prisma/prisma.service';
export declare class MatchesMessagesController {
    private prisma;
    constructor(prisma: PrismaService);
    getMatchMessages(matchId: string, req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, limit?: number): Promise<{
        id: string;
        created_at: Date;
        content: string;
        match_id: string;
        sender_id: string;
    }[]>;
}
