import { FriendsRepository } from './friends.repository';
import { ConversationsService } from '../conversations/conversations.service';
export declare class FriendsService {
    private friendsRepository;
    private conversationsService;
    constructor(friendsRepository: FriendsRepository, conversationsService: ConversationsService);
    sendFriendRequest(requesterId: string, targetUserId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    acceptRequest(userId: string, requestId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    rejectRequest(userId: string, requestId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    cancelRequest(userId: string, requestId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    listFriends(userId: string): Promise<{
        id: string;
        username: string;
        avatar_url: string | null;
    }[]>;
    listIncomingRequests(userId: string): Promise<{
        id: string;
        from: {
            id: string;
            username: string;
            avatar_url: string | null;
        };
        status: string;
        created_at: Date;
    }[]>;
    listOutgoingRequests(userId: string): Promise<{
        id: string;
        to: {
            id: string;
            username: string;
            avatar_url: string | null;
        };
        status: string;
        created_at: Date;
    }[]>;
    removeFriend(userId: string, friendId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
}
