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
            friendMatchId: null;
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
    createMessageForConversation(conversationId: string, userId: string, content: string): Promise<{
        id: string;
        created_at: Date;
        content: string;
        conversation_id: string;
        sender_id: string;
    }>;
    ensureFriendConversationBetweenUsers(userId: string, friendId: string): Promise<{
        id: string;
        type: import("@prisma/client").$Enums.ConversationType;
        title: string | null;
        friendMatchId: null;
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
            content: string;
            conversation_id: string;
            sender_id: string;
        }[];
        nextCursor: string | null;
    }>;
    private mapConversationToSummary;
}
