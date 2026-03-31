import { GroupsRepository } from './groups.repository';
export declare class GroupsService {
    private groupsRepository;
    constructor(groupsRepository: GroupsRepository);
    createGroup(ownerId: string, name: string): Promise<{
        id: string;
        name: string;
        invite_code: string;
    }>;
    joinGroupByInviteCode(userId: string, inviteCode: string): Promise<{
        id: string;
        name: string;
        invite_code: string;
    }>;
    leaveGroup(userId: string, groupId: string): Promise<{
        success: boolean;
    }>;
    listGroupMembers(requestingUserId: string, groupId: string): Promise<{
        id: string;
        username: string;
        avatar_url: string | null;
        is_self: boolean;
    }[]>;
    listMyGroups(userId: string): Promise<{
        id: string;
        name: string;
        invite_code: string;
    }[]>;
}
