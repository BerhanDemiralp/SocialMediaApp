import { Request as ExpressRequest } from 'express';
import { ConversationsService } from './conversations.service';
import { ListConversationsQueryDto } from './dto/list-conversations-query.dto';
import { GetConversationMessagesQueryDto } from './dto/get-conversation-messages-query.dto';
import { CreateFriendConversationDto } from './dto/create-friend-conversation.dto';
export declare class ConversationsController {
    private readonly conversationsService;
    constructor(conversationsService: ConversationsService);
    listConversations(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, query: ListConversationsQueryDto): Promise<{
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
    getConversationMessages(conversationId: string, req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, query: GetConversationMessagesQueryDto): Promise<{
        items: {
            id: string;
            created_at: Date;
            content: string;
            conversation_id: string;
            sender_id: string;
        }[];
        nextCursor: string | null;
    }>;
    createConversationMessage(conversationId: string, req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, body: {
        content?: string;
    }): Promise<{
        id: string;
        created_at: Date;
        content: string;
        conversation_id: string;
        sender_id: string;
    }>;
    createOrReuseFriendConversation(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, body: CreateFriendConversationDto): Promise<{
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
}
