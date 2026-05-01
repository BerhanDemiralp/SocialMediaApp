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
            groupId: string | null;
            groupName: string | null;
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
        sender: {
            email: string;
            username: string;
            id: string;
            avatar_url: string | null;
            created_at: Date;
            updated_at: Date;
        };
    } & {
        id: string;
        created_at: Date;
        content: string;
        deleted_at: Date | null;
        conversation_id: string;
        sender_id: string;
    }>;
    ensureFriendConversationBetweenUsers(userId: string, friendId: string): Promise<{
        id: string;
        type: import("@prisma/client").$Enums.ConversationType;
        title: string | null;
        friendMatchId: null;
        groupId: string | null;
        groupName: string | null;
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
        items: ({
            sender: {
                email: string;
                username: string;
                id: string;
                avatar_url: string | null;
                created_at: Date;
                updated_at: Date;
            };
        } & {
            id: string;
            created_at: Date;
            content: string;
            deleted_at: Date | null;
            conversation_id: string;
            sender_id: string;
        })[];
        nextCursor: string | null;
    }>;
    assertUserCanAccessConversation(conversationId: string, userId: string): Promise<void>;
    private assertCanAccessConversation;
    private mapConversationToSummary;
}
