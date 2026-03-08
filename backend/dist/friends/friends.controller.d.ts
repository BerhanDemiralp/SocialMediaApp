import { Request as ExpressRequest } from 'express';
import { FriendsService } from './friends.service';
import { SendFriendRequestDto } from './dto/send-friend-request.dto';
export declare class FriendsController {
    private friendsService;
    constructor(friendsService: FriendsService);
    sendFriendRequest(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, body: SendFriendRequestDto): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    acceptRequest(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, id: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    rejectRequest(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, id: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    cancelRequest(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, id: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
    listFriends(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }): Promise<{
        id: string;
        username: string;
        avatar_url: string | null;
    }[]>;
    listIncomingRequests(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }): Promise<{
        id: string;
        from: {
            id: string;
            username: string;
            avatar_url: string | null;
        };
        status: string;
        created_at: Date;
    }[]>;
    listOutgoingRequests(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }): Promise<{
        id: string;
        to: {
            id: string;
            username: string;
            avatar_url: string | null;
        };
        status: string;
        created_at: Date;
    }[]>;
    removeFriend(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, friendId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        requester_id: string;
        addressee_id: string;
        status: string;
    }>;
}
