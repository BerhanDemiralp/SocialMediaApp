import { Request as ExpressRequest } from 'express';
import { GroupsService } from './groups.service';
import { CreateGroupDto } from './dto/create-group.dto';
import { JoinGroupDto } from './dto/join-group.dto';
export declare class GroupsController {
    private groupsService;
    constructor(groupsService: GroupsService);
    createGroup(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, body: CreateGroupDto): Promise<{
        id: string;
        name: string;
        invite_code: string;
    }>;
    joinGroup(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, body: JoinGroupDto): Promise<{
        id: string;
        name: string;
        invite_code: string;
    }>;
    leaveGroup(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }, groupId: string): Promise<{
        success: boolean;
    }>;
    listMyGroups(req: ExpressRequest & {
        user?: {
            id: string;
        };
    }): Promise<{
        id: string;
        name: string;
        invite_code: string;
    }[]>;
}
