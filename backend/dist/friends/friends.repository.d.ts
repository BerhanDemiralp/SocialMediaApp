import { PrismaService } from '../prisma/prisma.service';
export declare class FriendsRepository {
    private prisma;
    constructor(prisma: PrismaService);
    findFriendshipById(id: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        status: string;
        addressee_id: string;
        requester_id: string;
    } | null>;
    findFriendshipBetweenUsers(userAId: string, userBId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        status: string;
        addressee_id: string;
        requester_id: string;
    } | null>;
    createFriendRequest(requesterId: string, addresseeId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        status: string;
        addressee_id: string;
        requester_id: string;
    }>;
    updateFriendshipStatus(id: string, status: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        status: string;
        addressee_id: string;
        requester_id: string;
    }>;
    listAcceptedFriendshipsForUser(userId: string): Promise<({
        addressee: {
            email: string;
            username: string;
            id: string;
            avatar_url: string | null;
            created_at: Date;
            updated_at: Date;
        };
        requester: {
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
        updated_at: Date;
        status: string;
        addressee_id: string;
        requester_id: string;
    })[]>;
    listIncomingRequests(userId: string): Promise<({
        requester: {
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
        updated_at: Date;
        status: string;
        addressee_id: string;
        requester_id: string;
    })[]>;
    listOutgoingRequests(userId: string): Promise<({
        addressee: {
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
        updated_at: Date;
        status: string;
        addressee_id: string;
        requester_id: string;
    })[]>;
}
