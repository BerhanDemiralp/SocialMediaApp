import { ConversationType } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
export declare class ConversationsService {
    private readonly prisma;
    constructor(prisma: PrismaService);
    listConversationsForUser(userId: string, limit?: number, cursor?: string, type?: ConversationType): Promise<{
        items: {
            id: string;
            type: import("@prisma/client").$Enums.ConversationType;
            title: string | null;
            friendMatchId: string | null;
            participants: {
                id: string;
                username: string;
                avatar_url: string | null;
            }[];
            lastMessage: {
                id: string;
                content: string;
                created_at: Date;
            } | null;
        }[];
        nextCursor: string | null;
    }>;
    ensureFriendConversationBetweenUsers(userId: string, friendId: string): Promise<{
        id: string;
        type: import("@prisma/client").$Enums.ConversationType;
        title: string | null;
        friendMatchId: string | null;
        participants: {
            id: string;
            username: string;
            avatar_url: string | null;
        }[];
        lastMessage: {
            id: string;
            content: string;
            created_at: Date;
        } | null;
    }>;
    getConversationMessages(conversationId: string, userId: string, limit?: number, cursor?: string): Promise<{
        items: {
            id: string;
            created_at: Date;
            conversation_id: string | null;
            match_id: string;
            sender_id: string;
            content: string;
        }[];
        nextCursor: string | null;
    }>;
    private mapConversationToSummary;
}
