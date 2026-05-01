import { PrismaService } from '../prisma/prisma.service';
export declare class GroupsRepository {
    private prisma;
    constructor(prisma: PrismaService);
    createGroupWithOwner(ownerId: string, name: string, inviteCode: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        name: string;
        deleted_at: Date | null;
        conversation_id: string | null;
        invite_code: string;
        created_by: string;
    }>;
    findGroupByInviteCode(inviteCode: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        name: string;
        deleted_at: Date | null;
        conversation_id: string | null;
        invite_code: string;
        created_by: string;
    } | null>;
    findMembership(userId: string, groupId: string): Promise<{
        id: string;
        joined_at: Date;
        group_id: string;
        user_id: string;
    } | null>;
    addMemberToGroup(userId: string, groupId: string): Promise<{
        group: {
            id: string;
            created_at: Date;
            updated_at: Date;
            name: string;
            deleted_at: Date | null;
            conversation_id: string | null;
            invite_code: string;
            created_by: string;
        };
    } & {
        id: string;
        joined_at: Date;
        group_id: string;
        user_id: string;
    }>;
    removeMemberFromGroup(userId: string, groupId: string): Promise<{
        id: string;
        joined_at: Date;
        group_id: string;
        user_id: string;
    }>;
    listGroupsForUser(userId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        name: string;
        deleted_at: Date | null;
        conversation_id: string | null;
        invite_code: string;
        created_by: string;
    }[]>;
    listMembersForGroup(groupId: string): Promise<{
        email: string;
        username: string;
        id: string;
        avatar_url: string | null;
        created_at: Date;
        updated_at: Date;
    }[]>;
    findGroupById(groupId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        name: string;
        deleted_at: Date | null;
        conversation_id: string | null;
        invite_code: string;
        created_by: string;
    } | null>;
    deleteGroupWithChat(groupId: string): Promise<{
        id: string;
        created_at: Date;
        updated_at: Date;
        name: string;
        deleted_at: Date | null;
        conversation_id: string | null;
        invite_code: string;
        created_by: string;
    } | null>;
}
